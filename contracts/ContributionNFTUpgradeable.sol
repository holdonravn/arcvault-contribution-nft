// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
  ArcVault Contribution NFT — v1.0.4 (upgradeable)
  Changes:
   - Custom errors (gas ↓)
   - Separate nonces: mintNonce / updateNonce
   - contribution(id) view helper
   - Keeps: per-token freeze, SBT lock in _update, EIP-712 mint/update, 4906 signals
*/

// ───────────────────── OpenZeppelin v4.9.5 (upgradeable) ─────────────────────
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/proxy/utils/Initializable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/proxy/utils/UUPSUpgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/access/AccessControlUpgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/token/ERC721/ERC721Upgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/token/common/ERC2981Upgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/utils/cryptography/EIP712Upgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/utils/cryptography/SignatureCheckerUpgradeable.sol";

contract ContributionNFTUpgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    EIP712Upgradeable,
    UUPSUpgradeable
{
    using SignatureCheckerUpgradeable for address;

    // ── Custom errors (gas-friendly)
    error ZeroTo();
    error BadScore();
    error NoSignerRole();
    error Expired();
    error BadNonce();
    error Frozen();
    error BadAdmin();

    // Version
    uint64 public contractVersion; // v1.0.4

    // Roles
    bytes32 public constant POLICY_ADMIN   = keccak256("POLICY_ADMIN");
    bytes32 public constant METADATA_ADMIN = keccak256("METADATA_ADMIN");
    bytes32 public constant SIGNER_ROLE    = keccak256("SIGNER_ROLE");

    // State
    uint256 public nextId;          // token ids (1’den başlar)
    string  private baseURIcustom;  // ipfs:// veya gateway
    bool    public  soulboundMode;  // true => transfer/approvals kilit
    mapping(uint256 => bool) public frozen; // per-token kalıcı freeze

    struct Contribution {
        string  cid;        // IPFS/gateway path
        uint8   category;   // 0..255
        uint8   score;      // 0..100
        address approver;   // son onaylayan
    }
    mapping(uint256 => Contribution) private info;

    // Signer nonces (separate channels)
    mapping(address => uint256) public mintNonce;
    mapping(address => uint256) public updateNonce;

    // Events
    event ContributionMinted(uint256 indexed tokenId, address indexed to, uint8 category, uint8 score, address indexed approver, string cid);
    event ContributionUpdated(uint256 indexed tokenId, uint8 score, address indexed approver, string cid);
    event MetadataFrozen(uint256 indexed tokenId);
    event BaseURISet(string uri);
    event SoulboundSet(bool on);
    event UpgradedTo(address indexed impl, address indexed by);
    // ERC-4906
    event MetadataUpdate(uint256 _tokenId);

    // EIP-712 typehash’ler
    bytes32 public constant MINT_TYPEHASH = keccak256(
        "MintRequest(address to,string cid,uint8 category,uint8 score,uint256 nonce,uint256 deadline,address signer)"
    );
    bytes32 public constant UPDATE_TYPEHASH = keccak256(
        "UpdateRequest(address signer,uint256 tokenId,string cid,uint8 score,uint256 nonce,uint256 deadline)"
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // secure impl
    }

    // Initialize
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address royaltyReceiver,
        uint96  royaltyFee,      // ör: 500 => %5
        address admin            // DEFAULT_ADMIN_ROLE (Timelock/Safe önerilir)
    ) public initializer {
        if (admin == address(0)) revert BadAdmin();

        __ERC721_init(name_, symbol_);
        __ERC721Pausable_init();
        __AccessControl_init();
        __ERC2981_init();
        __EIP712_init(name_, "1");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(POLICY_ADMIN,       admin);
        _grantRole(METADATA_ADMIN,     admin);
        _grantRole(SIGNER_ROLE,        admin);

        nextId = 1;
        baseURIcustom = baseURI_;
        emit BaseURISet(baseURI_);

        if (royaltyReceiver != address(0)) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFee);
        }

        contractVersion = 5; // v1.0.4
    }

    // ───────────── Admin utils ─────────────
    function setBaseURI(string calldata v) external onlyRole(METADATA_ADMIN) {
        baseURIcustom = v;
        emit BaseURISet(v);
    }

    function pause() external onlyRole(POLICY_ADMIN) { _pause(); }
    function unpause() external onlyRole(POLICY_ADMIN) { _unpause(); }

    function toggleSoulbound(bool on) external onlyRole(POLICY_ADMIN) {
        soulboundMode = on;
        emit SoulboundSet(on);
    }

    function setDefaultRoyalty(address receiver, uint96 fee) external onlyRole(METADATA_ADMIN) {
        _setDefaultRoyalty(receiver, fee);
    }
    function deleteDefaultRoyalty() external onlyRole(METADATA_ADMIN) {
        _deleteDefaultRoyalty();
    }

    // ───────────── Mint (EIP-712) ─────────────
    struct MintRequest {
        address to;
        string  cid;
        uint8   category;
        uint8   score;
        uint256 nonce;      // uses mintNonce[signer]
        uint256 deadline;
        address signer;     // SIGNER_ROLE sahibi
    }

    function mintWithSig(MintRequest calldata req, bytes calldata sig) external whenNotPaused {
        if (req.to == address(0)) revert ZeroTo();
        if (req.score > 100) revert BadScore();
        if (!hasRole(SIGNER_ROLE, req.signer)) revert NoSignerRole();
        if (block.timestamp > req.deadline) revert Expired();
        if (req.nonce != mintNonce[req.signer]) revert BadNonce();

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINT_TYPEHASH,
                    req.to,
                    keccak256(bytes(req.cid)),
                    req.category,
                    req.score,
                    req.nonce,
                    req.deadline,
                    req.signer
                )
            )
        );
        if (!req.signer.isValidSignatureNow(digest, sig)) revert BadNonce(); // generic fail; keeps error set minimal

        unchecked { mintNonce[req.signer] = req.nonce + 1; }

        uint256 tokenId = nextId++;
        info[tokenId] = Contribution({
            cid: req.cid,
            category: req.category,
            score: req.score,
            approver: req.signer
        });

        _safeMint(req.to, tokenId);

        emit ContributionMinted(tokenId, req.to, req.category, req.score, req.signer, req.cid);
        emit MetadataUpdate(tokenId); // ERC-4906
    }

    // ───────────── Update (EIP-712) ─────────────
    struct UpdateRequest {
        address signer;   // SIGNER_ROLE sahibi
        uint256 tokenId;
        string  cid;
        uint8   score;
        uint256 nonce;    // uses updateNonce[signer]
        uint256 deadline;
    }

    function updateWithSig(UpdateRequest calldata req, bytes calldata sig) external whenNotPaused {
        _requireExists(req.tokenId);
        if (frozen[req.tokenId]) revert Frozen();
        if (req.score > 100) revert BadScore();
        if (!hasRole(SIGNER_ROLE, req.signer)) revert NoSignerRole();
        if (block.timestamp > req.deadline) revert Expired();
        if (req.nonce != updateNonce[req.signer]) revert BadNonce();

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    UPDATE_TYPEHASH,
                    req.signer,
                    req.tokenId,
                    keccak256(bytes(req.cid)),
                    req.score,
                    req.nonce,
                    req.deadline
                )
            )
        );
        if (!req.signer.isValidSignatureNow(digest, sig)) revert BadNonce();

        unchecked { updateNonce[req.signer] = req.nonce + 1; }

        info[req.tokenId].cid      = req.cid;
        info[req.tokenId].score    = req.score;
        info[req.tokenId].approver = req.signer;

        emit ContributionUpdated(req.tokenId, req.score, req.signer, req.cid);
        emit MetadataUpdate(req.tokenId); // ERC-4906
    }

    // ───────────── Freeze (PAUSED iken ve per-token) ─────────────
    function freezeMetadata(uint256 tokenId) external onlyRole(METADATA_ADMIN) whenPaused {
        _requireExists(tokenId);
        frozen[tokenId] = true;           // kalıcı kilit
        emit MetadataFrozen(tokenId);
        emit MetadataUpdate(tokenId);
    }

    // ───────────── Soulbound gates ─────────────
    function approve(address to, uint256 tokenId) public override(ERC721Upgradeable) {
        require(!soulboundMode, "SBT: approve disabled");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable) {
        require(!soulboundMode, "SBT: approveAll disabled");
        super.setApprovalForAll(operator, approved);
    }

    // Transfer yolu (OZ 4.9): pause check ERC721Pausable’da; SBT kilidi burada kesilir.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
        returns (address)
    {
        if (soulboundMode) {
            address from = _ownerOf(tokenId); // internal getter
            if (from != address(0) && to != address(0)) {
                revert("SBT: transfer disabled");
            }
        }
        return super._update(to, tokenId, auth);
    }

    // ───────────── Views / Helpers ─────────────
    function _baseURI() internal view override returns (string memory) {
        return baseURIcustom;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireExists(tokenId);
        string memory base = _baseURI();
        string memory cid  = info[tokenId].cid;
        if (bytes(base).length == 0) return cid;
        if (bytes(cid).length == 0)  return base;

        bool baseEnds  = bytes(base)[bytes(base).length - 1] == "/";
        bool cidStarts = bytes(cid).length > 0 && bytes(cid)[0] == "/";
        if (baseEnds && cidStarts)   return string(abi.encodePacked(base, _slice1(cid)));
        if (!baseEnds && !cidStarts) return string(abi.encodePacked(base, "/", cid));
        return string(abi.encodePacked(base, cid));
    }

    function contribution(uint256 tokenId) external view returns (Contribution memory) {
        _requireExists(tokenId);
        return info[tokenId];
    }

    function _slice1(string memory s) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        if (b.length == 0) return s;
        bytes memory o = new bytes(b.length - 1);
        for (uint i=1; i<b.length; i++) o[i-1] = b[i];
        return string(o);
    }

    function _requireExists(uint256 tokenId) internal view {
        require(_exists(tokenId), "bad token");
    }

    // ───────────── UUPS ─────────────
    function _authorizeUpgrade(address newImpl)
        internal
        override
        onlyRole(POLICY_ADMIN)
    {
        emit UpgradedTo(newImpl, msg.sender);
    }

    // ───────────── Interfaces ─────────────
    function supportsInterface(bytes4 interfaceId)
        public view
        override(ERC721Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        if (interfaceId == 0x49064906) return true; // ERC-4906
        return super.supportsInterface(interfaceId);
    }
}

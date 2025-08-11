// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
  ArcVault Contribution NFT — Final (Upgradeable, EIP-712, Per-token Freeze, SBT Gate)
  - OpenZeppelin 4.9.5 (upgradeable) imports pinned by tag for Remix stability
  - UUPS upgradeable, role-based access, EIP-712 mint/update (EOA + ERC-1271)
  - Per-token freeze (hard lock), optional Soulbound mode (transfer/approvals off)
  - ERC-2981 royalty + ERC-4906 metadata update signals
*/

// ───────── OZ Upgradeable imports (v4.9.5) ─────────
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

    // ───────── Roles ─────────
    bytes32 public constant POLICY_ADMIN   = keccak256("POLICY_ADMIN");    // pause / SBT toggle
    bytes32 public constant METADATA_ADMIN = keccak256("METADATA_ADMIN");  // baseURI / royalty / freeze-global
    bytes32 public constant SIGNER_ROLE    = keccak256("SIGNER_ROLE");     // EIP-712 approvers
    bytes32 public constant UPGRADER_ROLE  = keccak256("UPGRADER_ROLE");   // UUPS authorize

    // ───────── Custom errors (gas) ─────────
    error ZeroTo();
    error BadScore();
    error BadNonce();
    error Expired();
    error NoSignerRole();
    error Frozen();

    // ───────── Storage ─────────
    uint256 public nextId;                 // token ids (starts from 1)
    string  private baseURIcustom;         // ipfs:// or gateway
    bool    public  soulboundMode;         // transfers/approvals off when true
    bool    public  metadataFrozenGlobal;  // locks baseURI & royalty

    struct Contribution {
        string  cid;        // IPFS / gateway path (full or partial)
        uint8   category;   // 0..255 (UI maps to labels)
        uint8   score;      // 0..100
        address approver;   // last approver (SIGNER_ROLE)
    }
    mapping(uint256 => Contribution) public info;

    // Per-token hard freeze
    mapping(uint256 => bool) public frozen;

    // Separate nonces for mint/update (per signer)
    mapping(address => uint256) public mintNonce;
    mapping(address => uint256) public updateNonce;

    // Supply counters
    uint256 public totalMinted;
    uint256 public totalBurned;

    // ───────── Events ─────────
    event ContributionMinted(
        uint256 indexed tokenId,
        address indexed to,
        uint8   category,
        uint8   score,
        address indexed approver,
        string  cid
    );
    event ContributionUpdated(
        uint256 indexed tokenId,
        uint8   score,
        address indexed approver,
        string  cid
    );

    event BaseURISet(string uri);
    event RoyaltySet(address receiver, uint96 fee);
    event RoyaltyCleared();

    event SoulboundToggled(bool enabled);
    event MetadataFrozen(uint256 indexed tokenId);

    // ERC-4906 signals
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    // ───────── EIP-712 typehashes ─────────
    bytes32 public constant MINT_TYPEHASH = keccak256(
        "MintRequest(address to,string cid,uint8 category,uint8 score,uint256 nonce,uint256 deadline,address signer)"
    );
    bytes32 public constant UPDATE_TYPEHASH = keccak256(
        "UpdateRequest(address signer,uint256 tokenId,string cid,uint8 score,uint256 nonce,uint256 deadline)"
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // implementation safety
    }

    // ───────── Initialize (proxy) ─────────
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address royaltyReceiver,
        uint96  royaltyFee,     // e.g. 500 = 5%
        address admin           // DEFAULT_ADMIN_ROLE (Timelock/Safe recommended)
    ) public initializer {
        require(admin != address(0), "admin=0");

        __ERC721_init(name_, symbol_);
        __ERC721Pausable_init();
        __AccessControl_init();
        __ERC2981_init();
        __EIP712_init(name_, "1");
        __UUPSUpgradeable_init();

        // Roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(POLICY_ADMIN,       admin);
        _grantRole(METADATA_ADMIN,     admin);
        _grantRole(SIGNER_ROLE,        admin);
        _grantRole(UPGRADER_ROLE,      admin);

        nextId = 1;
        baseURIcustom = baseURI_;
        emit BaseURISet(baseURI_);

        if (royaltyReceiver != address(0)) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFee);
            emit RoyaltySet(royaltyReceiver, royaltyFee);
        }
    }

    // ───────── Admin utils ─────────
    function setBaseURI(string calldata v) external onlyRole(METADATA_ADMIN) {
        if (metadataFrozenGlobal) revert Frozen();
        baseURIcustom = v;
        emit BaseURISet(v);

        // polite 4906 range
        uint256 last = nextId > 1 ? nextId - 1 : 0;
        if (last > 0) emit BatchMetadataUpdate(1, last);
    }

    function freezeGlobalMetadata() external onlyRole(METADATA_ADMIN) {
        metadataFrozenGlobal = true;
        // optional: emit a snapshot event via BatchMetadataUpdate
        uint256 last = nextId > 1 ? nextId - 1 : 0;
        if (last > 0) emit BatchMetadataUpdate(1, last);
    }

    function pause() external onlyRole(POLICY_ADMIN) { _pause(); }
    function unpause() external onlyRole(POLICY_ADMIN) { _unpause(); }

    function toggleSoulbound(bool on) external onlyRole(POLICY_ADMIN) {
        soulboundMode = on;
        emit SoulboundToggled(on);
    }

    function setDefaultRoyalty(address receiver, uint96 fee) external onlyRole(METADATA_ADMIN) {
        if (metadataFrozenGlobal) revert Frozen();
        _setDefaultRoyalty(receiver, fee);
        emit RoyaltySet(receiver, fee);
    }

    function deleteDefaultRoyalty() external onlyRole(METADATA_ADMIN) {
        if (metadataFrozenGlobal) revert Frozen();
        _deleteDefaultRoyalty();
        emit RoyaltyCleared();
    }

    // ───────── EIP-712 structs ─────────
    struct MintRequest {
        address to;
        string  cid;
        uint8   category;
        uint8   score;       // <= 100
        uint256 nonce;       // must equal mintNonce[signer]
        uint256 deadline;    // block.timestamp <= deadline
        address signer;      // must have SIGNER_ROLE
    }

    struct UpdateRequest {
        address signer;      // must have SIGNER_ROLE
        uint256 tokenId;
        string  cid;
        uint8   score;       // <= 100
        uint256 nonce;       // must equal updateNonce[signer]
        uint256 deadline;    // block.timestamp <= deadline
    }

    // ───────── Mint (EIP-712, supports EOA & ERC-1271) ─────────
    function mintWithSig(MintRequest calldata req, bytes calldata sig) external whenNotPaused {
        if (req.to == address(0)) revert ZeroTo();
        if (req.score > 100)      revert BadScore();
        if (!hasRole(SIGNER_ROLE, req.signer)) revert NoSignerRole();
        if (block.timestamp > req.deadline)    revert Expired();
        if (req.nonce != mintNonce[req.signer]) revert BadNonce();

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                MINT_TYPEHASH,
                req.to,
                keccak256(bytes(req.cid)),
                req.category,
                req.score,
                req.nonce,
                req.deadline,
                req.signer
            ))
        );
        require(req.signer.isValidSignatureNow(digest, sig), "invalid sig");

        // consume nonce
        unchecked { mintNonce[req.signer] = req.nonce + 1; }

        // CEI: write first
        uint256 tokenId = nextId++;
        info[tokenId] = Contribution({
            cid: req.cid,
            category: req.category,
            score: req.score,
            approver: req.signer
        });

        // mint
        _safeMint(req.to, tokenId);
        totalMinted += 1;

        emit ContributionMinted(tokenId, req.to, req.category, req.score, req.signer, req.cid);
        emit MetadataUpdate(tokenId); // ERC-4906
    }

    // ───────── Update (EIP-712) ─────────
    function updateWithSig(UpdateRequest calldata req, bytes calldata sig) external whenNotPaused {
        _requireExists(req.tokenId);
        if (frozen[req.tokenId])  revert Frozen();
        if (req.score > 100)      revert BadScore();
        if (!hasRole(SIGNER_ROLE, req.signer)) revert NoSignerRole();
        if (block.timestamp > req.deadline)    revert Expired();
        if (req.nonce != updateNonce[req.signer]) revert BadNonce();

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                UPDATE_TYPEHASH,
                req.signer,
                req.tokenId,
                keccak256(bytes(req.cid)),
                req.score,
                req.nonce,
                req.deadline
            ))
        );
        require(req.signer.isValidSignatureNow(digest, sig), "invalid sig");

        unchecked { updateNonce[req.signer] = req.nonce + 1; }

        // apply update
        info[req.tokenId].cid      = req.cid;
        info[req.tokenId].score    = req.score;
        info[req.tokenId].approver = req.signer;

        emit ContributionUpdated(req.tokenId, req.score, req.signer, req.cid);
        emit MetadataUpdate(req.tokenId); // ERC-4906
    }

    // ───────── Per-token hard freeze ─────────
    // Policy choice: require pause to freeze (gives community a visible window)
    function freezeMetadata(uint256 tokenId) external onlyRole(METADATA_ADMIN) whenPaused {
        _requireExists(tokenId);
        frozen[tokenId] = true;
        emit MetadataFrozen(tokenId);
        emit MetadataUpdate(tokenId);
    }

    // ───────── ERC721 overrides ─────────

    // SBT: approvals blocked
    function approve(address to, uint256 tokenId) public override {
        require(!soulboundMode, "SBT: approve disabled");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(!soulboundMode, "SBT: approveAll disabled");
        super.setApprovalForAll(operator, approved);
    }

    // Transfers funnel through OZ 4.9 _update(to, tokenId, auth)
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
        returns (address)
    {
        // ERC721Pausable enforces pause here; we add SBT gate
        if (soulboundMode) {
            address from = _ownerOf(tokenId);
            if (from != address(0) && to != address(0)) {
                revert("SBT: transfer disabled");
            }
        }
        return super._update(to, tokenId, auth);
    }

    // Burn: if SBT on, only owner; else owner/approved
    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (soulboundMode) {
            require(msg.sender == owner, "SBT: only owner burn");
        } else {
            require(
                msg.sender == owner ||
                getApproved(tokenId) == msg.sender ||
                isApprovedForAll(owner, msg.sender),
                "not owner/approved"
            );
        }
        _burn(tokenId);
        totalBurned += 1;
        emit MetadataUpdate(tokenId);
    }

    // Views
    function totalSupply() external view returns (uint256) {
        return totalMinted - totalBurned;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIcustom;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireExists(tokenId);
        string memory base = _baseURI();
        string memory cid  = info[tokenId].cid;
        if (bytes(base).length == 0) return cid;
        if (bytes(cid).length  == 0) return base;

        bool baseEnds  = bytes(base)[bytes(base).length - 1] == "/";
        bool cidStarts = bytes(cid).length > 0 && bytes(cid)[0] == "/";
        if (baseEnds && cidStarts)   return string(abi.encodePacked(base, _slice1(cid)));
        if (!baseEnds && !cidStarts) return string(abi.encodePacked(base, "/", cid));
        return string(abi.encodePacked(base, cid));
    }

    // ───────── Internals ─────────
    function _slice1(string memory s) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        if (b.length == 0) return s;
        bytes memory o = new bytes(b.length - 1);
        for (uint i = 1; i < b.length; i++) o[i-1] = b[i];
        return string(o);
    }

    function _requireExists(uint256 tokenId) internal view {
        // OZ 4.9: use internal owner map
        require(_ownerOf(tokenId) != address(0), "bad token");
    }

    // ───────── UUPS authorize ─────────
    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    // ───────── Interfaces ─────────
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        if (interfaceId == 0x49064906) return true; // ERC-4906
        return super.supportsInterface(interfaceId);
    }
}

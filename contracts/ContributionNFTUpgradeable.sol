// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*  ArcVault Contribution NFT (Upgradeable, “Vitalik-grade”)
    - OZ 4.9.5 upgradeable importları pinli (supply-chain hygiene)
    - EIP-712 imzalı Mint/Update (EOA + EIP-1271)
    - Soulbound toggle + token-bazlı freeze
    - ERC721 + ERC2981 + Pausable + AccessControl + UUPS
    - Opsiyonel EAS attestation (schema/adres verilirse)
*/

// ---------- OpenZeppelin (upgradeable) ----------
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/proxy/utils/Initializable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/proxy/utils/UUPSUpgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/access/AccessControlUpgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/token/ERC721/ERC721Upgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/token/common/ERC2981Upgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/utils/cryptography/EIP712Upgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/utils/cryptography/SignatureCheckerUpgradeable.sol";

// ---------- Optional EAS (minimal interface) ----------
interface IEAS {
    function attest(bytes32 schema, bytes calldata data) external returns (bytes32 uid);
}

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

    // -------- Roles --------
    bytes32 public constant POLICY_ADMIN   = keccak256("POLICY_ADMIN");    // pause, SBT, policy ops
    bytes32 public constant METADATA_ADMIN = keccak256("METADATA_ADMIN");  // baseURI & royalty
    bytes32 public constant SIGNER_ROLE    = keccak256("SIGNER_ROLE");     // EIP-712 onaylayıcılar

    // -------- Custom errors (gas) --------
    error Frozen();
    error BadNonce();
    error BadScore();
    error ZeroTo();
    error NoSignerRole();
    error Expired();

    // -------- Storage --------
    uint256 public nextId;                 // token ids (1'den başlar)
    string  private baseURIcustom;         // "ipfs://..." ya da gateway
    bool    public soulboundMode;          // SBT açıkken transfer/approve kilidi

    struct Contribution {
        string  cid;                       // IPFS path / URL
        uint8   category;                  // 0..255
        uint8   score;                     // 0..100
        address approver;                  // son onaylayan (signer)
    }
    mapping(uint256 => Contribution) public info;

    // token-bazlı freeze
    mapping(uint256 => bool) public frozen;

    // imzacı nonceları (kanal ayrımı)
    mapping(address => uint256) public mintNonce;
    mapping(address => uint256) public updateNonce;

    // arz metrikleri
    uint256 public totalMinted;
    uint256 public totalBurned;

    // Opsiyonel EAS
    IEAS    public eas;          // 0 ise pasif
    bytes32 public schemaId;     // şema id

    // -------- Events --------
    event ContributionMinted(uint256 indexed tokenId, address indexed to, uint8 category, uint8 score, address indexed approver, string cid);
    event ContributionUpdated(uint256 indexed tokenId, uint8 score, address indexed approver, string cid);
    event BaseURISet(string uri);
    event MetadataFrozen(uint256 indexed tokenId);
    event SoulboundToggled(bool enabled);
    // ERC-4906
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    // -------- EIP-712 typehash’ler --------
    bytes32 public constant MINT_TYPEHASH = keccak256(
        "MintRequest(address to,string cid,uint8 category,uint8 score,uint256 nonce,uint256 deadline,address signer)"
    );
    bytes32 public constant UPDATE_TYPEHASH = keccak256(
        "UpdateRequest(address signer,uint256 tokenId,string cid,uint8 score,uint256 nonce,uint256 deadline)"
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    // -------- Initialize (proxy) --------
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address royaltyReceiver,
        uint96  royaltyFee,       // ör: 500 => %5
        address admin             // DEFAULT_ADMIN_ROLE → timelock/Gnosis önerilir
    ) public initializer {
        require(admin != address(0), "admin zero");

        __ERC721_init(name_, symbol_);
        __ERC721Pausable_init();
        __AccessControl_init();
        __ERC2981_init();
        __EIP712_init(name_, "1");
        __UUPSUpgradeable_init();

        // roller
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(POLICY_ADMIN,       admin);
        _grantRole(METADATA_ADMIN,     admin);
        _grantRole(SIGNER_ROLE,        admin);

        // baseURI + royalty
        baseURIcustom = baseURI_;
        emit BaseURISet(baseURI_);

        if (royaltyReceiver != address(0)) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFee);
        }

        nextId = 1; // tokenId 1'den
    }

    // -------- Admin utils --------
    function setBaseURI(string calldata v) external onlyRole(METADATA_ADMIN) {
        baseURIcustom = v;
        emit BaseURISet(v);
        // indexer’lar için nazik sinyal: 1..(nextId-1)
        if (nextId > 1) emit BatchMetadataUpdate(1, nextId - 1);
    }

    function pause() external onlyRole(POLICY_ADMIN) { _pause(); }
    function unpause() external onlyRole(POLICY_ADMIN) { _unpause(); }

    function toggleSoulbound(bool on) external onlyRole(POLICY_ADMIN) {
        soulboundMode = on;
        emit SoulboundToggled(on);
    }

    function setDefaultRoyalty(address receiver, uint96 fee) external onlyRole(METADATA_ADMIN) {
        _setDefaultRoyalty(receiver, fee);
    }
    function deleteDefaultRoyalty() external onlyRole(METADATA_ADMIN) {
        _deleteDefaultRoyalty();
    }

    // Opsiyonel EAS kurulumu
    function setEAS(address eas_, bytes32 schema_) external onlyRole(POLICY_ADMIN) {
        eas      = IEAS(eas_);
        schemaId = schema_;
    }

    // -------- Mint (EIP-712) --------
    struct MintRequest {
        address to;
        string  cid;
        uint8   category;
        uint8   score;
        uint256 nonce;
        uint256 deadline;
        address signer; // SIGNER_ROLE sahibi
    }

    function mintWithSig(MintRequest calldata req, bytes calldata sig) external whenNotPaused {
        if (req.to == address(0)) revert ZeroTo();
        if (req.score > 100)      revert BadScore();
        if (!hasRole(SIGNER_ROLE, req.signer)) revert NoSignerRole();
        if (block.timestamp > req.deadline)    revert Expired();
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
        require(req.signer.isValidSignatureNow(digest, sig), "invalid sig");

        // nonce tüket
        unchecked { mintNonce[req.signer] = req.nonce + 1; }

        // state → sonra mint (CEI)
        uint256 tokenId = nextId++;
        info[tokenId] = Contribution({
            cid: req.cid,
            category: req.category,
            score: req.score,
            approver: req.signer
        });

        _safeMint(req.to, tokenId);
        unchecked { totalMinted++; }

        // Opsiyonel attestation
        if (address(eas) != address(0) && schemaId != bytes32(0)) {
            bytes memory data = abi.encode(tokenId, req.cid, req.category, req.score, req.signer);
            eas.attest(schemaId, data);
        }

        emit ContributionMinted(tokenId, req.to, req.category, req.score, req.signer, req.cid);
        emit MetadataUpdate(tokenId);
    }

    // -------- Update (EIP-712) --------
    struct UpdateRequest {
        address signer;   // SIGNER_ROLE sahibi
        uint256 tokenId;
        string  cid;
        uint8   score;
        uint256 nonce;
        uint256 deadline;
    }

    function updateWithSig(UpdateRequest calldata req, bytes calldata sig) external whenNotPaused {
        _requireExists(req.tokenId);
        if (frozen[req.tokenId])  revert Frozen();
        if (req.score > 100)      revert BadScore();
        if (!hasRole(SIGNER_ROLE, req.signer)) revert NoSignerRole();
        if (block.timestamp > req.deadline)    revert Expired();
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
        require(req.signer.isValidSignatureNow(digest, sig), "invalid sig");

        unchecked { updateNonce[req.signer] = req.nonce + 1; }

        info[req.tokenId].cid      = req.cid;
        info[req.tokenId].score    = req.score;
        info[req.tokenId].approver = req.signer;

        // Opsiyonel attestation
        if (address(eas) != address(0) && schemaId != bytes32(0)) {
            bytes memory data = abi.encode(req.tokenId, req.cid, info[req.tokenId].category, req.score, req.signer);
            eas.attest(schemaId, data);
        }

        emit ContributionUpdated(req.tokenId, req.score, req.signer, req.cid);
        emit MetadataUpdate(req.tokenId);
    }

    // -------- Freeze (token-bazlı, kalıcı) --------
    // İsteğe bağlı: paused iken çağrılmasını zorunlu kılmak için whenPaused ekleyebilirsin.
    function freezeMetadata(uint256 tokenId) external onlyRole(METADATA_ADMIN) {
        _requireExists(tokenId);
        frozen[tokenId] = true;
        emit MetadataFrozen(tokenId);
        emit MetadataUpdate(tokenId);
    }

    // -------- Approvals kapıları (SBT) --------
    function approve(address to, uint256 tokenId) public override {
        require(!soulboundMode, "SBT: approve disabled");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(!soulboundMode, "SBT: approveAll disabled");
        super.setApprovalForAll(operator, approved);
    }

    // -------- Burn --------
    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        // SBT açıkken sadece sahibi yakabilir
        if (soulboundMode) {
            require(msg.sender == owner, "SBT: only owner");
        } else {
            require(
                msg.sender == owner ||
                getApproved(tokenId) == msg.sender ||
                isApprovedForAll(owner, msg.sender),
                "not owner/approved"
            );
        }
        _burn(tokenId);
        unchecked { totalBurned++; }
        emit MetadataUpdate(tokenId);
    }

    // -------- Views --------
    function _baseURI() internal view override returns (string memory) {
        return baseURIcustom;
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted - totalBurned;
    }

    function _requireExists(uint256 tokenId) internal view {
        require(_ownerOf(tokenId) != address(0), "bad token");
    }

    // -------- Transfer hook (OZ 4.9) --------
    // Pause check, ERC721Pausable’ın kendi _update’ında zaten var.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
        returns (address)
    {
        if (soulboundMode) {
            address from = _ownerOf(tokenId);
            // mint/burn serbest; normal transfer yasak
            if (from != address(0) && to != address(0)) {
                revert("SBT: transfer disabled");
            }
        }
        return super._update(to, tokenId, auth);
    }

    // -------- UUPS authorize --------
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(POLICY_ADMIN)
    {}

    // -------- Interfaces --------
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

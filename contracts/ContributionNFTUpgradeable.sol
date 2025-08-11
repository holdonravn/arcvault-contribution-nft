// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
  Final upgradeable ERC-721 (UUPS) with roles, pause, royalties, soulbound gate,
  global metadata freeze and ERC-4906 signals.

  NOTE (for Remix/GitHub):
  - Imports are pinned to OpenZeppelin 4.9.5 (upgradeable) via GitHub URLs.
  - Works with Solidity compiler 0.8.20+.
*/

// ───────────────────────── OZ (upgradeable) imports ─────────────────────────
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/proxy/utils/Initializable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/proxy/utils/UUPSUpgradeable.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/access/AccessControlUpgradeable.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/token/ERC721/ERC721Upgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/token/common/ERC2981Upgradeable.sol";

// ───────────────────────── Contract ─────────────────────────
contract ContributionNFTUpgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // -------- Roles --------
    bytes32 public constant PAUSER_ROLE    = keccak256("PAUSER_ROLE");     // pause/unpause + soulbound toggle
    bytes32 public constant MINTER_ROLE    = keccak256("MINTER_ROLE");     // mint
    bytes32 public constant METADATA_ADMIN = keccak256("METADATA_ADMIN");  // baseURI & royalty
    bytes32 public constant UPGRADER_ROLE  = keccak256("UPGRADER_ROLE");   // UUPS authorize

    // -------- State --------
    bool    public soulboundMode;      // true => transfer & approvals disabled (except mint/burn)
    bool    public metadataFrozen;     // true => baseURI & royalty setters locked
    string  private _baseTokenURI;
    uint256 private _nextId;           // auto-increment tokenId (starts at 1)

    // -------- Events --------
    event Minted(address indexed to, uint256 indexed tokenId, address indexed by);
    event BaseURISet(string uri);
    event MetadataFrozen();
    event RoyaltySet(address receiver, uint96 fee);
    event RoyaltyCleared();

    // ERC-4906 metadata update signals
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ---------------- Initialize (constructor yerine) ----------------
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address admin,               // DEFAULT_ADMIN_ROLE (Timelock / Safe önerilir)
        address royaltyReceiver,     // 2981 receiver (0 ise atlanır)
        uint96  royaltyFee           // ör: 500 = %5
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Pausable_init();
        __AccessControl_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();

        // Roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE,        admin);
        _grantRole(MINTER_ROLE,        admin);
        _grantRole(METADATA_ADMIN,     admin);
        _grantRole(UPGRADER_ROLE,      admin);

        // Base URI + Royalty
        _baseTokenURI = baseTokenURI_;
        emit BaseURISet(baseTokenURI_);

        if (royaltyReceiver != address(0)) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFee);
            emit RoyaltySet(royaltyReceiver, royaltyFee);
        }

        _nextId = 1; // token IDs start at 1
    }

    // ---------------- Mint (auto tokenId) ----------------
    function safeMint(address to) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(to != address(0), "ARC: zero to");
        uint256 tokenId = _nextId++;
        _safeMint(to, tokenId);
        emit Minted(to, tokenId, msg.sender);
        emit MetadataUpdate(tokenId); // ERC-4906 hint
    }

    // ---------------- Metadata ----------------
    function setBaseURI(string calldata newBaseURI) external onlyRole(METADATA_ADMIN) {
        require(!metadataFrozen, "ARC: metadata frozen");
        _baseTokenURI = newBaseURI;
        emit BaseURISet(newBaseURI);
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    function freezeMetadata() external onlyRole(METADATA_ADMIN) {
        metadataFrozen = true;
        emit MetadataFrozen();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // ---------------- Royalties (ERC-2981) ----------------
    function setDefaultRoyalty(address receiver, uint96 fee)
        external
        onlyRole(METADATA_ADMIN)
    {
        require(!metadataFrozen, "ARC: metadata frozen");
        _setDefaultRoyalty(receiver, fee);
        emit RoyaltySet(receiver, fee);
    }

    function deleteDefaultRoyalty()
        external
        onlyRole(METADATA_ADMIN)
    {
        require(!metadataFrozen, "ARC: metadata frozen");
        _deleteDefaultRoyalty();
        emit RoyaltyCleared();
    }

    // ---------------- Soulbound gates ----------------
    function setSoulboundMode(bool enabled) external onlyRole(PAUSER_ROLE) {
        soulboundMode = enabled;
    }

    function approve(address to, uint256 tokenId)
        public
        override(ERC721Upgradeable)
    {
        require(!soulboundMode, "ARC: approve disabled (SBT)");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable)
    {
        require(!soulboundMode, "ARC: approveAll disabled (SBT)");
        super.setApprovalForAll(operator, approved);
    }

    // ---------------- Burn (optional) ----------------
    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
            getApproved(tokenId) == msg.sender ||
            isApprovedForAll(owner, msg.sender),
            "ARC: not owner/approved"
        );
        _burn(tokenId);
        emit MetadataUpdate(tokenId);
    }

    // ---------------- Pause ----------------
    function pause() external onlyRole(PAUSER_ROLE) { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    // ---------------- Transfer hook (OZ v4.9) ----------------
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Block transfers when soulbound (allow mint: from==0, allow burn: to==0)
        if (soulboundMode && from != address(0) && to != address(0)) {
            revert("ARC: transfer disabled (SBT)");
        }
    }

    // ---------------- UUPS authorize ----------------
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // ---------------- Interfaces ----------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        // ERC-4906
        if (interfaceId == 0x49064906) return true;
        return super.supportsInterface(interfaceId);
    }

    // ---------------- Helpers ----------------
    function _requireExists(uint256 tokenId) internal view {
        // OZ v4.9-compatible existence check (no _requireMinted dependency)
        require(_ownerOf(tokenId) != address(0), "ARC: bad token");
    }

    // ---------------- Storage gap (upgrade safety) ----------------
    uint256[50] private __gap;
}

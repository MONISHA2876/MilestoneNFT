// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title MilestoneNFT - Simple ERC721-style NFT issuer for milestone rewards
/// @notice No imports, no constructor, admin address is hardcoded (replace before deploy).
contract MilestoneNFT {
    // ---- CONFIG / ADMIN ----
    address public constant ADMIN = 0x1111111111111111111111111111111111111111; // replace before deploy

    // ---- ERC-721 STORAGE ----
    string private _name = "MilestoneNFT";
    string private _symbol = "MILE";
    uint256 private _nextTokenId;

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // metadata
    string private _baseURI;
    mapping(uint256 => string) private _tokenURI;

    // milestone info per token
    mapping(uint256 => string) private _milestoneOfToken;

    // total supply (simple counter)
    uint256 public totalSupply;

    // ---- EVENTS (ERC721-ish) ----
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // milestone event
    event MilestoneAwarded(address indexed to, uint256 indexed tokenId, string milestone, string tokenURI);

    // ---- MODIFIERS ----
    modifier onlyAdmin() {
        require(msg.sender == ADMIN, "only admin");
        _;
    }

    // ---- ERC-721 BASIC FUNCTIONS ----

    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "zero address");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "token doesn't exist");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_ownerOf[tokenId] != address(0), "token doesn't exist");
        string memory uri = _tokenURI[tokenId];
        // if token-specific URI set, return it; otherwise return baseURI + tokenId (naive concat)
        if (bytes(uri).length > 0) {
            return uri;
        }
        if (bytes(_baseURI).length == 0) {
            return "";
        }
        return string(abi.encodePacked(_baseURI, _toString(tokenId)));
    }

    // Approvals
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(to != owner, "approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "not authorized");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_ownerOf[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "operator is sender");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Transfers (non-safe)
    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(owner == from, "not owner");
        require(to != address(0), "transfer to zero");
        require(
            msg.sender == owner ||
            getApproved(tokenId) == msg.sender ||
            isApprovedForAll(owner, msg.sender),
            "not approved"
        );

        _beforeTokenTransfer(from, to, tokenId);

        // clear approvals
        _tokenApprovals[tokenId] = address(0);

        // update balances & owner
        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    // ---- MINT / BURN & MILESTONE LOGIC (ADMIN) ----

    /// @notice Admin awards an NFT to `to` for achieving `milestone`. Optionally attach `uri`.
    /// @param to recipient address
    /// @param uri optional tokenURI (leave empty "" to use baseURI + tokenId)
    /// @param milestone short string describing the milestone (stored on-chain)
    function awardMilestoneNFT(address to, string calldata uri, string calldata milestone) external onlyAdmin returns (uint256) {
        require(to != address(0), "zero recipient");
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        totalSupply += 1;

        if (bytes(uri).length > 0) {
            _tokenURI[tokenId] = uri;
        }

        if (bytes(milestone).length > 0) {
            _milestoneOfToken[tokenId] = milestone;
        }

        emit MilestoneAwarded(to, tokenId, milestone, uri);
        return tokenId;
    }

    /// @notice Admin can burn a token (e.g., revoke reward). Can also be used by token owner.
    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || msg.sender == ADMIN || isApprovedForAll(owner, msg.sender) || getApproved(tokenId) == msg.sender, "not authorized to burn");
        _burn(tokenId);
    }

    // Admin can update base URI for off-chain metadata hosting
    function setBaseURI(string calldata newBase) external onlyAdmin {
        _baseURI = newBase;
    }

    // View milestone for a token
    function milestoneOf(uint256 tokenId) external view returns (string memory) {
        require(_ownerOf[tokenId] != address(0), "token doesn't exist");
        return _milestoneOfToken[tokenId];
    }

    // Convenience: list tokens owned by an address (note: O(n) over tokenId range)
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        require(owner != address(0), "zero address");
        uint256 cnt = _balanceOf[owner];
        uint256[] memory result = new uint256[](cnt);
        if (cnt == 0) return result;

        uint256 found = 0;
        for (uint256 id = 0; id < _nextTokenId; id++) {
            if (_ownerOf[id] == owner) {
                result[found++] = id;
                if (found == cnt) break;
            }
        }
        return result;
    }

    // ---- INTERNAL HELPERS ----

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "mint to zero");
        require(_ownerOf[tokenId] == address(0), "token exists");

        _beforeTokenTransfer(address(0), to, tokenId);

        _ownerOf[tokenId] = to;
        _balanceOf[to] += 1;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // clear approvals
        _tokenApprovals[tokenId] = address(0);

        // reduce balances & delete owner
        _balanceOf[owner] -= 1;
        delete _ownerOf[tokenId];

        // clear metadata and milestone
        if (bytes(_tokenURI[tokenId]).length > 0) delete _tokenURI[tokenId];
        if (bytes(_milestoneOfToken[tokenId]).length > 0) delete _milestoneOfToken[tokenId];

        totalSupply -= 1;

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    // Hooks for extension (empty now)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

    // Very small uint -> string helper
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


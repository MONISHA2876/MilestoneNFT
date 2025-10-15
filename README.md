# 🎖️ MilestoneNFT Smart Contract

**MilestoneNFT** is an on-chain reward system that issues **NFTs for milestone achievements** — ideal for recognizing contributions, performance, or project progress.  
Each NFT represents a verified milestone and carries a unique metadata URI.

---

## 📍 Contract Information

- **Network:** Testnet  
- **Contract Address:** [`0x573bC0fc396Cf1703C79090728eE27f416034297`](https://explorer.testnet.io/address/0x573bC0fc396Cf1703C79090728eE27f416034297)  
- **Standard:** Custom ERC-721 (no imports)  
- **Compiler Version:** `^0.8.19`  
- **Admin:** Hardcoded inside the contract (must be updated before deployment)  
- **License:** MIT  

---

## ⚙️ Features

✅ **No Imports / No Constructor** – Fully self-contained contract  
✅ **Admin-Controlled Minting** – Only admin can issue milestone NFTs  
✅ **ERC721-Compatible** – Supports transfer, approvals, and balance tracking  
✅ **Metadata Support** – Each NFT can have a custom `tokenURI`  
✅ **Milestone Tracking** – Each NFT stores an on-chain milestone description  
✅ **Base URI Customization** – Admin can update base metadata URI  
✅ **Burnable Tokens** – Admin or owner can revoke NFTs  

---

## 🧠 Core Functions

| Function | Description |
|-----------|--------------|
| `awardMilestoneNFT(address to, string uri, string milestone)` | Admin mints a new NFT as a reward for a milestone. |
| `setBaseURI(string newBase)` | Admin updates the base URI for metadata. |
| `milestoneOf(uint256 tokenId)` | Returns the milestone text associated with a token. |
| `transferFrom(address from, address to, uint256 tokenId)` | Transfer ownership of a token. |
| `burn(uint256 tokenId)` | Burn (revoke) an NFT — callable by admin or token owner. |
| `tokensOfOwner(address owner)` | Returns all token IDs owned by an address. |

---

## 🏷️ Example Workflow

1. **Admin awards milestone:**
   ```solidity
   awardMilestoneNFT(0xUserAddress, "ipfs://QmHashOfMetadata", "Completed Phase 1");

2. **User checks their NFT:**
   ```solidity
   tokensOfOwner(0xUserAddress);
    milestoneOf(tokenId);
    tokenURI(tokenId);

3. **Transfer NFT (optional):**
   ```solidity
   transferFrom(0xUserAddress, 0xAnotherUser, tokenId);

4. **Admin updates metadata (if needed):**
   ```solidity
   setBaseURI("https://myproject-metadata.xyz/nft/");


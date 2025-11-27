// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AnmolProfile
 * @dev Simple on-chain profile registry for a single handle pattern like "Anmol@@8821"
 * @notice Allows an address to claim a unique handle and update basic metadata
 */
contract AnmolProfile {
    address public owner;

    struct Profile {
        string handle;        // e.g. "Anmol@@8821"
        string displayName;   // friendly name
        string metadataURI;   // optional URI with extended profile data
        uint256 createdAt;
        uint256 updatedAt;
        bool exists;
    }

    // address => Profile
    mapping(address => Profile) public profiles;

    // handle hash => address (to enforce uniqueness)
    mapping(bytes32 => address) public handleOwner;

    event ProfileCreated(
        address indexed user,
        string handle,
        string displayName,
        uint256 timestamp
    );

    event ProfileUpdated(
        address indexed user,
        string handle,
        string displayName,
        string metadataURI,
        uint256 timestamp
    );

    event HandleTransferred(
        address indexed from,
        address indexed to,
        string handle,
        uint256 timestamp
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Claim a new handle (one per address)
     * @param handle The unique handle string, e.g. "Anmol@@8821"
     * @param displayName Initial display name
     * @param metadataURI Optional profile metadata URI
     */
    function claimProfile(
        string calldata handle,
        string calldata displayName,
        string calldata metadataURI
    ) external {
        require(!profiles[msg.sender].exists, "Profile exists");
        bytes32 hHash = keccak256(bytes(handle));
        require(handleOwner[hHash] == address(0), "Handle taken");

        profiles[msg.sender] = Profile({
            handle: handle,
            displayName: displayName,
            metadataURI: metadataURI,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            exists: true
        });

        handleOwner[hHash] = msg.sender;

        emit ProfileCreated(msg.sender, handle, displayName, block.timestamp);
        emit ProfileUpdated(msg.sender, handle, displayName, metadataURI, block.timestamp);
    }

    /**
     * @dev Update own profile metadata
     * @param displayName New display name
     * @param metadataURI New metadata URI
     */
    function updateProfile(
        string calldata displayName,
        string calldata metadataURI
    ) external {
        Profile storage p = profiles[msg.sender];
        require(p.exists, "No profile");

        p.displayName = displayName;
        p.metadataURI = metadataURI;
        p.updatedAt = block.timestamp;

        emit ProfileUpdated(msg.sender, p.handle, displayName, metadataURI, block.timestamp);
    }

    /**
     * @dev Transfer a handle/profile to another address
     * @param to Recipient address
     */
    function transferProfile(address to) external {
        require(to != address(0), "Zero address");
        require(!profiles[to].exists, "Recipient has profile");

        Profile storage pFrom = profiles[msg.sender];
        require(pFrom.exists, "No profile");

        // move profile struct
        profiles[to] = Profile({
            handle: pFrom.handle,
            displayName: pFrom.displayName,
            metadataURI: pFrom.metadataURI,
            createdAt: pFrom.createdAt,
            updatedAt: block.timestamp,
            exists: true
        });

        // update handle owner mapping
        bytes32 hHash = keccak256(bytes(pFrom.handle));
        handleOwner[hHash] = to;

        // delete old
        delete profiles[msg.sender];

        emit HandleTransferred(msg.sender, to, profiles[to].handle, block.timestamp);
    }

    /**
     * @dev Get profile by address (view helper)
     */
    function getProfile(address user)
        external
        view
        returns (
            string memory handle,
            string memory displayName,
            string memory metadataURI,
            uint256 createdAt,
            uint256 updatedAt,
            bool exists
        )
    {
        Profile memory p = profiles[user];
        return (p.handle, p.displayName, p.metadataURI, p.createdAt, p.updatedAt, p.exists);
    }

    /**
     * @dev Resolve handle to owner address
     * @param handle Handle string
     */
    function resolveHandle(string calldata handle) external view returns (address) {
        return handleOwner[keccak256(bytes(handle))];
    }

    /**
     * @dev Transfer contract ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}

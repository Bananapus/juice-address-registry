// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IJBAddressRegistry } from './interfaces/IJBAddressRegistry.sol';

/// @notice  This contract is used to register deployers of Juicebox Delegates. It is the deployer responsability to register their delegates in this registry and make sure the delegate implements IERC165
/// @dev Mostly for front-end integration purposes. The delegate address is computed from the deployer address and the nonce used to deploy the delegate.
contract JBAddressRegistry is IJBAddressRegistry {

    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//

    error JBAddressRegistry_incompatibleAddress();

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    /// @notice  Track which deployer deployed an address, based on a proactive deployer update.
    /// @custom:param addr The address that was deployed.
    mapping(address addr => address deployer) public override deployerOf;

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//  

    constructor() {}

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /// @notice Add a delegate to the registry (needs to implement erc165, a delegate type and deployed using create)
    /// @param deployer The address of the deployer of a given address.
    /// @param nonce The nonce used to deploy the address.
    function addAddressDeployedFrom(address deployer, uint256 nonce) external override {
        // Compute the _delegate address, as create1 deployed at _nonce
        address delegate = _addressFrom(deployer, nonce);

        // Add the delegate based on the computed address
        _addDelegate(delegate, deployer);
    }

    /// @notice Add an address to the registry.
    /// @dev `salt` is based on the delegate deployer own internal logic while the deployment bytecode can be retrieved in the deployment transaction (off-chain) or via abi.encodePacked(type(delegateContract).creationCode, abi.encode(constructorArguments)) (on-chain)
    /// @param deployer The address of the address's deployer.
    /// @param salt A unique salt used to deploy the delegate.
    /// @param bytecode The deployment bytecode used to deploy the delegate (ie including constructor and its arguments)
    function addAddressDeployedFrom(address deployer, bytes32 salt, bytes calldata bytecode) external override {
        // Compute the _delegate address, based on create2 salt and deployment bytecode
        address delegate = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            keccak256(bytecode)
        )))));

        // Add the delegate based on the computed address
        _addDelegate(delegate, deployer);
    }

    //*********************************************************************//
    // ---------------------- private transactions ----------------------- //
    //*********************************************************************//

    /// @notice Add an address to the mapping.
    /// @param addr The address.
    /// @param deployer The deployer address.
    function _addDelegate(address addr, address deployer) private {
        deployerOf[addr] = deployer;

        emit AddressAdded(addr, deployer);
    }

    /// @notice Compute the address of a contract deployed using create1, by an address at a given nonce.
    /// @dev Taken from https://ethereum.stackexchange.com/a/87840/68134 - this wouldn't work for nonce > 2**32, if someone do reach that nonce please: 1) ping us, because wow 2) use another deployer.
    /// @param origin The address of the deployer.
    /// @param nonce The nonce used to deploy the contract.
    function _addressFrom(address origin, uint nonce) internal pure returns (address addr) {
        bytes memory data;
        if(nonce == 0x00)          data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), origin, bytes1(0x80));
        else if(nonce <= 0x7f)     data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), origin, uint8(nonce));
        else if(nonce <= 0xff)     data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), origin, bytes1(0x81), uint8(nonce));
        else if(nonce <= 0xffff)   data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), origin, bytes1(0x82), uint16(nonce));
        else if(nonce <= 0xffffff) data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), origin, bytes1(0x83), uint24(nonce));
        else                        data = abi.encodePacked(bytes1(0xda), bytes1(0x94), origin, bytes1(0x84), uint32(nonce));
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }
}
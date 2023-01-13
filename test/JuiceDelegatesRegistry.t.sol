// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import "@juice-delegate-registry/JuiceDelegatesRegistry.sol";
import "forge-std/Test.sol";

contract JuiceDelegatesRegistryTest is Test {
    event DelegateAdded(address indexed _delegate, address indexed _deployer);

    address _owner = makeAddr("_owner");
    address _deployer = makeAddr("_deployer");

    JuiceDelegatesRegistry registry;

    /**
     * @dev Setup is deploying the registry and set one address as trusted deployer, for later use
     */
    function setUp() public {
        vm.startPrank(_owner);
        registry = new JuiceDelegatesRegistry();
        registry.setDeployer(_deployer, true);
        vm.stopPrank();
    }

    /**
     * @custom:test When adding a pay delegate, the transaction is successful, correct event is emited and the delegate is added to the mapping
     */
    function test_addTrustedDelegate_addPayDelegate() public {
        address _delegate = makeAddr("_delegate");
        vm.etch(_delegate, '69420');

        // mock the erc165 calls
        vm.mockCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IERC165).interfaceId),
            abi.encode(true)
        );

        vm.mockCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IJBPayDelegate).interfaceId),
            abi.encode(true)
        );

        // Check: Is the check for erc165 support made?
        vm.expectCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IERC165).interfaceId)
        );

        // Check: Is the check for pay delegate support made?
        vm.expectCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IJBPayDelegate).interfaceId)
        );
        
        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_delegate, _deployer);

        // -- transaction --
        vm.prank(_deployer);
        registry.addTrustedDelegate(_delegate);

        // Check: is delegate added to the mapping, with the sender as deployer?
        assertTrue(registry.trustedJuiceDelegates(_delegate) == _deployer);
    }

    /**
     * @custom:test When adding a redemption delegate, the transaction is successful, correct event is emited and the delegate is added to the mapping
     */
    function test_addTrustedDelegate_addRedemptionDelegate() public {
        address _delegate = makeAddr("_delegate");
        vm.etch(_delegate, '69420');

        // mock the erc165 calls
        vm.mockCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IERC165).interfaceId),
            abi.encode(true)
        );

        vm.mockCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IJBRedemptionDelegate).interfaceId),
            abi.encode(true)
        );

        // Check: Is the check for erc165 support made?
        vm.expectCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IERC165).interfaceId)
        );

        // Check: Is the check for redemption delegate support made?
        vm.expectCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IJBRedemptionDelegate).interfaceId)
        );

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_delegate, _deployer);
        
        // -- transaction --
        vm.prank(_deployer);
        registry.addTrustedDelegate(_delegate);

        // Check: is delegate added to the mapping, with the sender as deployer?
        assertTrue(registry.trustedJuiceDelegates(_delegate) == _deployer);
    }

    /**
     * @custom:test When adding a contract which doesn't implement IERC165, the transaction reverts
     */
    function test_addTrustedDelegate_revert_notERC165() public {
        // There is a bytecode at the _delegate address (vm.etch) but no IERC165 mocked call
        address _delegate = makeAddr("_delegate");
        vm.etch(_delegate, '69420');
        
        // Check: Is the transaction reverting?
        vm.expectRevert(abi.encodeWithSelector(JuiceDelegatesRegistry.juiceDelegatesRegistry_incompatibleDelegate.selector));
        vm.prank(_deployer);

        // -- transaction --
        registry.addTrustedDelegate(_delegate);
    }

    /**
     * @custom:test When adding a contract which doesn't implement IJBPayDelegate or IJBRedemptionDelegate, the transaction reverts
     */
    function test_addTrustedDelegate_revert_notDelegate() public {
        address _delegate = makeAddr("_delegate");
        vm.etch(_delegate, '69420');

        // mock the erc165 calls
        vm.mockCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IERC165).interfaceId),
            abi.encode(true)
        );

        vm.mockCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IJBPayDelegate).interfaceId),
            abi.encode(false)
        );

        vm.mockCall(
            _delegate,
            abi.encodeCall(IERC165.supportsInterface, type(IJBRedemptionDelegate).interfaceId),
            abi.encode(false)
        );

        // Check: Is the transaction reverting?
        vm.expectRevert(abi.encodeWithSelector(JuiceDelegatesRegistry.juiceDelegatesRegistry_incompatibleDelegate.selector));

        // -- transaction --
        vm.prank(_deployer);
        registry.addTrustedDelegate(_delegate);
    }

    /**
     * @custom:test When adding a delegate which is not a contract, the transaction reverts
     */
    function test_addTrustedDelegate_revert_notAContract() public {
        address _delegate = makeAddr("_delegate");

        // Check: Is the transaction reverting?       
        vm.expectRevert(abi.encodeWithSelector(JuiceDelegatesRegistry.juiceDelegatesRegistry_incompatibleDelegate.selector));
        vm.prank(_deployer);

        // -- transaction --
        registry.addTrustedDelegate(_delegate);
    }
}
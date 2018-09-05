/**********************************************************************
*These solidity codes have been obtained from Etherscan for extracting
*the smartcontract related info.
*The data will be used by MATRIX AI team as the reference basis for
*MATRIX model analysis,extraction of contract semantics,
*as well as AI based data analysis, etc.
**********************************************************************/
pragma solidity ^0.4.13;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    require(b > 0);
    uint c = a / b;
    // require(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    require(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

/**
 * @dev used to restrict functionality to the contract owner
 */
contract Ownable {

  address public owner;

  modifier onlyOwner {
    require (msg.sender == owner);
    _;
  }

  function Ownable() {
    owner = msg.sender;
  }

  function setNewOwner(address _owner) public onlyOwner returns(bool success) {
    if (_owner != address(0)) {
      owner = _owner;
      return true;
    }
    return false;
  }
}

/**
 * @dev moved lock events in extra contract so they remain testable
 */
contract LockEvents {
  event Locked();
  event Unlocked();
}

/**
 * @dev enables owner to lock token transfer or other functionality
 */
contract Lockable is Ownable, LockEvents {

  bool public locked;

  modifier whenUnlocked() {
    require(locked==false);
    _;
  }

  modifier whenLocked() {
    require(locked==true);
    _;
  }

  function Lockable() {
    locked = true;
    Locked();
  }

  function unlock() public onlyOwner whenLocked returns(bool success) {
    locked = false;
    Unlocked();
    return true;
  }

  function lock() public onlyOwner whenUnlocked returns(bool success) {
    locked = true;
    Locked();
    return true;
  }
}

contract TimedVaultEvents {
  event Locked(address _target, uint256 timestamp);
}

/**
 * @dev blocks an address from certain actions over a period of time
 */
contract TimedVault is Ownable, TimedVaultEvents {
  mapping (address => uint256) lockDeadline;

  modifier timedVaultIsOpen(address _target) {
    require(now > lockDeadline[_target]);
    _;
  }

  function setVaultLock(address _target, uint256 timestamp) internal onlyOwner returns(bool success) {
    lockDeadline[_target] = timestamp;
    Locked(_target, timestamp);
    return true;
  }

  function getVaultLock(address _target) public returns(uint256 timestamp) {
    return lockDeadline[_target];
  }
}

/**
 * @dev moved lock events in extra contract so they remain testable
 */
contract ERC20Events {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Events {
  
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalSupply;

  /// @return total amount of tokens
  function totalSupply() public constant returns (uint256) {
    return totalSupply;
  }

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {
    //check if sender can afford and that there is no overflow on receiver side
    if(balances[msg.sender] >= _value 
      && balances[_to]+_value > balances[_to]) {

      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }
  
  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value 
      && allowed[_from][msg.sender] >= _value 
      && balances[_to] + _value > balances[_to]) {

      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { 
      return false; 
    }
  }

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success) {
    // mitigates the ERC20 spend/approval race condition
    if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract IdiotToken is Lockable, ERC20, TimedVault {
  
  string public name = "Idiot Token";
  string public symbol = "IDT";
  uint public decimals = 18;
  uint MULTIPLIER = 1000000000000000000; 

  function IdiotToken() {
    totalSupply = 76000000*MULTIPLIER;
    balances[owner] = totalSupply;
  }

  function transfer(address _to, uint256 _value) whenUnlocked timedVaultIsOpen(msg.sender) public returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferInitialAllocation(address _to, uint256 _value) onlyOwner public returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferInitialAllocationWithTimedLock(address _to, uint256 _value, uint256 _timestamp) onlyOwner public returns (bool success) {
    //lock first, then transfer to avoid race condition
    return (setVaultLock(_to, _timestamp) && super.transfer(_to, _value));
  }

  function transferFrom(address _from, address _to, uint256 _value) whenUnlocked public returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) whenUnlocked public returns (bool success) {
    return super.approve(_spender, _value);
  }

  // cannot send funds to IdiotToken directly
  function() payable {
    revert();
  }
}


/*
Token byte code
0x6060604052670de0b6b3a7640000600c55341561001b57600080fd5b5b5b60008054600160a060020a03191633600160a060020a03161790555b6004805462ffffff1916905561004d610106565b604051809103906000f080151561006357600080fd5b60078054600160a060020a0392909216600160a060020a0319928316179055600060065560088054821673383c69259149bdd38b5093bf1c75ebd44368428817905560098054821673c6f29a076cc937917f3cd608881c0b0a0b3276f2179055600a80548216738995b6645d60975cb14be68b6495be2618a77b94179055600b8054909116736e121956a9c8e4b3d1f7a7d3316056cd89ed109c1790555b610116565b604051610e8980610ec883390190565b610da3806101256000396000f300606060405236156100eb5763ffffffff60e060020a6000350416630a0cd8c881146100fc5780630bf318a3146101235780630dcf4b8f1461014a578063116b556b1461016f5780632c4e722e1461019e578063365b94ad146101c357806339dd134c146101ea5780634ee0ab0d1461021957806355a0184514610240578063560334c614610267578063806ba6d6146102965780638da5cb5b146102c5578063a4821719146102f4578063ba0bba40146102fe578063be9a655514610325578063dd54291b1461034a578063efbe1c1c1461036f578063f5a1f5b414610394578063fc0c546a146103c7575b6100fa5b6100f76103f6565b5b565b005b341561010757600080fd5b61010f6105af565b604051901515815260200160405180910390f35b341561012e57600080fd5b61010f6105be565b604051901515815260200160405180910390f35b341561015557600080fd5b61015d610779565b60405190815260200160405180910390f35b341561017a57600080fd5b61018261077f565b604051600160a060020a03909116815260200160405180910390f35b34156101a957600080fd5b61015d61078e565b60405190815260200160405180910390f35b34156101ce57600080fd5b61010f610794565b604051901515815260200160405180910390f35b34156101f557600080fd5b61018261079d565b604051600160a060020a03909116815260200160405180910390f35b341561022457600080fd5b61010f6107ac565b604051901515815260200160405180910390f35b341561024b57600080fd5b61010f61086f565b604051901515815260200160405180910390f35b341561027257600080fd5b61018261087d565b604051600160a060020a03909116815260200160405180910390f35b34156102a157600080fd5b61018261088c565b604051600160a060020a03909116815260200160405180910390f35b34156102d057600080fd5b61018261089b565b604051600160a060020a03909116815260200160405180910390f35b6100fa6103f6565b005b341561030957600080fd5b61010f6108aa565b604051901515815260200160405180910390f35b341561033057600080fd5b61015d610c97565b60405190815260200160405180910390f35b341561035557600080fd5b61015d610c9d565b60405190815260200160405180910390f35b341561037a57600080fd5b61015d610ca3565b60405190815260200160405180910390f35b341561039f57600080fd5b61010f600160a060020a0360043516610ca9565b604051901515815260200160405180910390f35b34156103d257600080fd5b610182610d0e565b604051600160a060020a03909116815260200160405180910390f35b60008060015411801561041757504260025411158015610417575060035442105b5b8015610427575060045460ff16155b801561043b5750600454610100900460ff16155b801561044f575060045462010000900460ff165b151561045a57600080fd5b662386f26fc1000034101561046e57600080fd5b61049b670de0b6b3a764000061048f34600554610d1d90919063ffffffff16565b9063ffffffff610d4f16565b905080600154101515156104ae57600080fd5b600180548290039055600754600160a060020a031663f7dc0455338360006040516020015260405160e060020a63ffffffff8516028152600160a060020a0390921660048301526024820152604401602060405180830381600087803b151561051657600080fd5b6102c65a03f1151561052757600080fd5b50505060405180515050600054600160a060020a03163480156108fc0290604051600060405180830381858888f19350505050151561056557600080fd5b6006805434019055600160a060020a0333167f2499a5330ab0979cc612135e7883ebc3cd5c9f7a8508f042540c34723348f6328260405190815260200160405180910390a25b5b50565b60045462010000900460ff1681565b6000805433600160a060020a039081169116146105da57600080fd5b60015415806105f7575042600254111580156105f7575060035442105b5b8061060a5750600454610100900460ff165b151561061557600080fd5b600060015411156106af5760075460008054600154600160a060020a039384169363f7dc0455939216916040516020015260405160e060020a63ffffffff8516028152600160a060020a0390921660048301526024820152604401602060405180830381600087803b151561068957600080fd5b6102c65a03f1151561069a57600080fd5b5050506040518051905015156106af57600080fd5b5b60075460008054600160a060020a039283169263f5a1f5b4929116906040516020015260405160e060020a63ffffffff8416028152600160a060020a039091166004820152602401602060405180830381600087803b151561071157600080fd5b6102c65a03f1151561072257600080fd5b50505060405180519050151561073757600080fd5b6004805460ff191660011790557f0734f1adc097bd79a3404c9d255d53ced9e8fef12f9718038823aa8265e51c3460405160405180910390a15060015b5b5b90565b60065481565b600854600160a060020a031681565b60055481565b60045460ff1681565b600a54600160a060020a031681565b6000805433600160a060020a039081169116146107c857600080fd5b60006001541180156107e8575042600254111580156107e8575060035442105b5b80156107f8575060045460ff16155b801561080c5750600454610100900460ff16155b8015610820575060045462010000900460ff165b151561082b57600080fd5b6004805461ff0019166101001790557f0734f1adc097bd79a3404c9d255d53ced9e8fef12f9718038823aa8265e51c3460405160405180910390a15060015b5b5b90565b600454610100900460ff1681565b600b54600160a060020a031681565b600954600160a060020a031681565b600054600160a060020a031681565b6000805433600160a060020a039081169116146108c657600080fd5b60045462010000900460ff16156108dc57600080fd5b6359f70630600255635a40da3060035560075460008054600c54600160a060020a039384169363f7dc04559392169163015be680909102906040516020015260405160e060020a63ffffffff8516028152600160a060020a0390921660048301526024820152604401602060405180830381600087803b151561095e57600080fd5b6102c65a03f1151561096f57600080fd5b50505060405180515050600754600854600c54600160a060020a03928316926334d5fc4b9216906273f780026301e13380420160006040516020015260405160e060020a63ffffffff8616028152600160a060020a03909316600484015260248301919091526044820152606401602060405180830381600087803b15156109f657600080fd5b6102c65a03f11515610a0757600080fd5b50505060405180515050600754600954600c54600160a060020a03928316926334d5fc4b9216906273f780026301e13380420160006040516020015260405160e060020a63ffffffff8616028152600160a060020a03909316600484015260248301919091526044820152606401602060405180830381600087803b1515610a8e57600080fd5b6102c65a03f11515610a9f57600080fd5b50505060405180515050600754600b54600c54600160a060020a039283169263f7dc045592169062685ec00260006040516020015260405160e060020a63ffffffff8516028152600160a060020a0390921660048301526024820152604401602060405180830381600087803b1515610b1757600080fd5b6102c65a03f11515610b2857600080fd5b50505060405180515050600754600a54600c54600160a060020a039283169263f7dc0455921690620b98c00260006040516020015260405160e060020a63ffffffff8516028152600160a060020a0390921660048301526024820152604401602060405180830381600087803b1515610ba057600080fd5b6102c65a03f11515610bb157600080fd5b50505060405180515050600c546301cfde0002600155600754600160a060020a03166370a082313060006040516020015260405160e060020a63ffffffff8416028152600160a060020a039091166004820152602401602060405180830381600087803b1515610c2057600080fd5b6102c65a03f11515610c3157600080fd5b5050506040518051600154149050610c4857600080fd5b600c546176c0026005556004805462ff00001916620100001790557f912ee23dde46ec889d6748212cce445d667f7041597691dc89e8549ad8bc0acb60405160405180910390a15060015b5b90565b60025481565b60015481565b60035481565b6000805433600160a060020a03908116911614610cc557600080fd5b600160a060020a03821615610d0457506000805473ffffffffffffffffffffffffffffffffffffffff1916600160a060020a0383161790556001610d08565b5060005b5b919050565b600754600160a060020a031681565b6000828202831580610d395750828482811515610d3657fe5b04145b1515610d4457600080fd5b8091505b5092915050565b600080808311610d5e57600080fd5b8284811515610d6957fe5b0490508091505b50929150505600a165627a7a72305820638ed212557f89ac3f1f6d45d713bf785fe2d71dc6148b4bb53fa5ea8e04fb2b0029606060405260408051908101604052600b81527f4964696f7420546f6b656e0000000000000000000000000000000000000000006020820152600590805161004b929160200190610150565b5060408051908101604052600381527f494454000000000000000000000000000000000000000000000000000000000060208201526006908051610093929160200190610150565b506012600755670de0b6b3a764000060085534156100b057600080fd5b5b5b5b60008054600160a060020a03191633600160a060020a03161790555b6000805460a060020a60ff021916740100000000000000000000000000000000000000001790557f0f2e5b6c72c6a4491efd919a9f9a409f324ef0708c11ee57d410c2cb06c0992b60405160405180910390a15b600854630487ab0002600381905560008054600160a060020a03168152600160205260409020555b6101f0565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061019157805160ff19168380011785556101be565b828001600101855582156101be579182015b828111156101be5782518255916020019190600101906101a3565b5b506101cb9291506101cf565b5090565b6101ed91905b808211156101cb57600081556001016101d5565b5090565b90565b610c8a806101ff6000396000f300606060405236156100ee5763ffffffff7c010000000000000000000000000000000000000000000000000000000060003504166306fdde0381146100fb578063095ea7b31461018657806318160ddd146101bc57806323b872dd146101e1578063313ce5671461021d57806334d5fc4b14610242578063587181d11461027b57806370a08231146102ac5780638da5cb5b146102dd57806395d89b411461030c578063a69df4b514610397578063a9059cbb146103be578063cf309012146103f4578063dd62ed3e1461041b578063f5a1f5b414610452578063f7dc045514610485578063f83d08ba146104bb575b6100f95b600080fd5b565b005b341561010657600080fd5b61010e6104e2565b60405160208082528190810183818151815260200191508051906020019080838360005b8381101561014b5780820151818401525b602001610132565b50505050905090810190601f1680156101785780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b341561019157600080fd5b6101a8600160a060020a0360043516602435610580565b604051901515815260200160405180910390f35b34156101c757600080fd5b6101cf6105ac565b60405190815260200160405180910390f35b34156101ec57600080fd5b6101a8600160a060020a03600435811690602435166044356105b3565b604051901515815260200160405180910390f35b341561022857600080fd5b6101cf6105e1565b60405190815260200160405180910390f35b341561024d57600080fd5b6101a8600160a060020a03600435166024356044356105e7565b604051901515815260200160405180910390f35b341561028657600080fd5b6101cf600160a060020a036004351661062a565b60405190815260200160405180910390f35b34156102b757600080fd5b6101cf600160a060020a0360043516610649565b60405190815260200160405180910390f35b34156102e857600080fd5b6102f0610668565b604051600160a060020a03909116815260200160405180910390f35b341561031757600080fd5b61010e610677565b60405160208082528190810183818151815260200191508051906020019080838360005b8381101561014b5780820151818401525b602001610132565b50505050905090810190601f1680156101785780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34156103a257600080fd5b6101a8610715565b604051901515815260200160405180910390f35b34156103c957600080fd5b6101a8600160a060020a036004351660243561079f565b604051901515815260200160405180910390f35b34156103ff57600080fd5b6101a86107f2565b604051901515815260200160405180910390f35b341561042657600080fd5b6101cf600160a060020a0360043581169060243516610802565b60405190815260200160405180910390f35b341561045d57600080fd5b6101a8600160a060020a036004351661082f565b604051901515815260200160405180910390f35b341561049057600080fd5b6101a8600160a060020a0360043516602435610894565b604051901515815260200160405180910390f35b34156104c657600080fd5b6101a86108c4565b604051901515815260200160405180910390f35b60058054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156105785780601f1061054d57610100808354040283529160200191610578565b820191906000526020600020905b81548152906001019060200180831161055b57829003601f168201915b505050505081565b6000805460a060020a900460ff161561059857600080fd5b6105a28383610950565b90505b5b92915050565b6003545b90565b6000805460a060020a900460ff16156105cb57600080fd5b6105d68484846109fc565b90505b5b9392505050565b60075481565b6000805433600160a060020a0390811691161461060357600080fd5b61060d8483610b12565b80156105d657506105d68484610b9b565b5b90505b5b9392505050565b600160a060020a0381166000908152600460205260409020545b919050565b600160a060020a0381166000908152600160205260409020545b919050565b600054600160a060020a031681565b60068054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156105785780601f1061054d57610100808354040283529160200191610578565b820191906000526020600020905b81548152906001019060200180831161055b57829003601f168201915b505050505081565b6000805433600160a060020a0390811691161461073157600080fd5b60005460a060020a900460ff16151560011461074c57600080fd5b6000805474ff0000000000000000000000000000000000000000191690557f19aad37188a1d3921e29eb3c66acf43d81975e107cb650d58cca878627955fd660405160405180910390a15060015b5b5b90565b6000805460a060020a900460ff16156107b757600080fd5b33600160a060020a03811660009081526004602052604090205442116107dc57600080fd5b6107e68484610b9b565b91505b5b505b92915050565b60005460a060020a900460ff1681565b600160a060020a038083166000908152600260209081526040808320938516835292905220545b92915050565b6000805433600160a060020a0390811691161461084b57600080fd5b600160a060020a0382161561088a57506000805473ffffffffffffffffffffffffffffffffffffffff1916600160a060020a0383161790556001610644565b5060005b5b919050565b6000805433600160a060020a039081169116146108b057600080fd5b6105a28383610b9b565b90505b5b92915050565b6000805433600160a060020a039081169116146108e057600080fd5b60005460a060020a900460ff16156108f757600080fd5b6000805474ff0000000000000000000000000000000000000000191660a060020a1790557f0f2e5b6c72c6a4491efd919a9f9a409f324ef0708c11ee57d410c2cb06c0992b60405160405180910390a15060015b5b5b90565b600081158015906109855750600160a060020a0333811660009081526002602090815260408083209387168352929052205415155b15610992575060006105a5565b600160a060020a03338116600081815260026020908152604080832094881680845294909152908190208590557f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259085905190815260200160405180910390a35060015b92915050565b600160a060020a038316600090815260016020526040812054829010801590610a4c5750600160a060020a0380851660009081526002602090815260408083203390941683529290522054829010155b8015610a715750600160a060020a038316600090815260016020526040902054828101115b15610b0257600160a060020a03808416600081815260016020908152604080832080548801905588851680845281842080548990039055600283528184203390961684529490915290819020805486900390559091907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9085905190815260200160405180910390a35060016105d9565b5060006105d9565b5b9392505050565b6000805433600160a060020a03908116911614610b2e57600080fd5b600160a060020a038316600090815260046020526040908190208390557f9f1ec8c880f76798e7b793325d625e9b60e4082a553c98f42b6cda368dd60008908490849051600160a060020a03909216825260208201526040908101905180910390a15060015b5b92915050565b600160a060020a033316600090815260016020526040812054829010801590610bdd5750600160a060020a038316600090815260016020526040902054828101115b15610c4f57600160a060020a033381166000818152600160205260408082208054879003905592861680825290839020805486019055917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9085905190815260200160405180910390a35060016105a5565b5060006105a5565b5b929150505600a165627a7a72305820d170d9c1c9e4f00b234466e1ad2a22838a1dd11a79216fce62137def3032e2790029
*/

contract IdiotTokenSale is Ownable {
  using SafeMath for uint;

  event Purchase(address indexed _buyer, uint256 _value);
  event SaleStarted();
  event SaleFinished();

  uint256 public tokenCap;
  uint public start;
  uint public end;
  bool public saleFinished;
  bool public forceFinished;
  bool public setupDone;
  uint256 public rate;
  uint public totalContribution;

  IdiotToken public token;

  address public founder1;
  address public founder2;
  address public advisoryPool;
  address public angelPool;
  uint MULTIPLIER = 1000000000000000000;

  modifier saleInProgress() {
    require(tokenCap > 0 && (start <= now && now < end) && !saleFinished && !forceFinished && setupDone);
    _;
  }

  modifier saleIsOver() {
    require(tokenCap == 0 || (start <= now && now < end) || forceFinished);
    _;
  }

  function IdiotTokenSale() {   
    setupDone = false;
    saleFinished = false;
    forceFinished = false;
    token = new IdiotToken();
    totalContribution = 0;

    founder1 = address(0x383C69259149BDd38B5093Bf1c75ebD443684288);
    founder2 = address(0xc6f29A076cc937917F3cd608881C0B0a0b3276f2);
    advisoryPool = address(0x8995b6645d60975Cb14be68B6495Be2618a77B94);
    angelPool = address(0x6e121956a9C8E4b3D1F7a7D3316056cD89eD109C);
  }

  function setup() public onlyOwner returns(bool success){
    require(!setupDone);

    start = 1509361200; // new Date("Oct 30 2017 11:00:00 GMT").getTime() / 1000
    end = 1514199600; // new Date("Dec 25 2017 11:00:00 GMT").getTime() / 1000

    // 30% Idiot Foundation as working capital
    token.transferInitialAllocation(owner, 22800000*MULTIPLIER); 
    // 20% Founders, locked away for a year
    token.transferInitialAllocationWithTimedLock(founder1, 7600000*MULTIPLIER, now + 365 days);
    token.transferInitialAllocationWithTimedLock(founder2, 7600000*MULTIPLIER, now + 365 days);
    // 10% Angel investors & advisors
    token.transferInitialAllocation(angelPool, 6840000*MULTIPLIER); 
    token.transferInitialAllocation(advisoryPool, 760000*MULTIPLIER);
    // 40% crowdsale
    tokenCap = 30400000*MULTIPLIER;
    require(tokenCap == token.balanceOf(this));

    rate = 30400*MULTIPLIER;

    setupDone = true;
    SaleStarted();
    return true;
  }

  function buyToken() public payable saleInProgress {
    require (msg.value >= 10 finney);
    uint purchasedToken = rate.mul(msg.value).div(1 ether);
    
    require(tokenCap >= purchasedToken);
    tokenCap -= purchasedToken;
    token.transferInitialAllocation(msg.sender, purchasedToken);
    
    require(owner.send(msg.value));
    totalContribution += msg.value;
    Purchase(msg.sender, purchasedToken);
  }

  function finalizeCrowdsale() public onlyOwner saleIsOver returns(bool success) {
    if (tokenCap > 0) {
      require(token.transferInitialAllocation(owner, tokenCap));
    }
    require(token.setNewOwner(owner));
    saleFinished = true;
    SaleFinished();
    return true;
  }

  function forceEnd() public onlyOwner saleInProgress returns(bool success) {
    forceFinished = true;
    SaleFinished();
    return true;
  }

  function () external payable {
    buyToken();
  }
}
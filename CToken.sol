pragma solidity >=0.4.21 <0.6.0;

import "./LockableToken.sol";
contract CToken is LockableToken {
  using SafeMath for uint256;

  string public constant name = "CToken";
  string public constant symbol = "CC";
  uint8  public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 2000 * (10 ** uint256(decimals));
  uint256 public constant RESERV_SUPPLY  = 1000 * (10 ** uint256(decimals));
event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;
event Transfer(
       address sender,
       address receiver,
       uint256 amount
    );
  constructor()
    public
  {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = totalSupply_;
  }

  // Dangerous function block
  function renounceOwnership() public onlyOwner {
    revert("Owner Only!");
  }

function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value,"Insufficient value to perform transfer");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from],"Insufficient value");
        require(_value <= allowance[_from][msg.sender],"Insufficient value");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}
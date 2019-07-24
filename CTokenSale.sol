pragma solidity >=0.4.21 <0.6.0;

import "../node_modules/openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "./SplitFundCrowdsale.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CToken.sol";

contract CTokenSale is TimedCrowdsale, Ownable, SplitFundCrowdsale {
  using SafeMath for uint256;



  CToken _token;

  uint256 public bonusRate;
  uint256 public calcAdditionalRatio;
  uint256 public cumulativeSumofToken;

  event SetPeriod(uint256 _openingTime, uint256 _closingTime);
  event TokenLocked(address beneficiary, uint256 amount);


  // Constructor
  // Fixed exchange ratio: 50000 (FIXED!)
  // Fixed period of sale: 4 weeks from now set as sales period (changeable)
  // Fixed Wallet A rate: 85 % (changeable)
  constructor(
    CToken _token_,
    address _walletA,
    address _walletB
  )
    public
    Crowdsale(50000, _walletA, _token_)
    TimedCrowdsale(block.timestamp, block.timestamp + 4 weeks)
    SplitFundCrowdsale(_walletA, _walletB, 85)
  {
    _token = _token_;

    emit SetPeriod(openingTime, closingTime);

 
  }

  // override fuction. default + bonus token
  function _getTokenAmount(
    uint256 _weiAmount
  )
    internal
    view
    returns (uint256)
  {
    return (_weiAmount.mul(rate)).add(_weiAmount.mul(calcAdditionalRatio)) ;
  }

  // override fuction.
  // Minimum limit is      0.5 eth =      500000000000000000 wei
  // Maximum limit is 20,000   eth = 20000000000000000000000 wei
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    onlyWhileOpen
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount >= 500000000000000000);
    require(_weiAmount <= 20000000000000000000000);
  }


  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    uint256 lockBalance = _weiAmount.mul(calcAdditionalRatio);

    _token.increaseLockBalance(_beneficiary, lockBalance);

    emit TokenLocked(
        _beneficiary,
        lockBalance
    );



    return;
  }

 

  // Change open, close time and bonus rate. _openingTime, _closingTime is epoch (= 1532919600)
  function changePeriod(
    uint256 _openingTime,
    uint256 _closingTime
  )
    onlyOwner
    external
    returns (bool)
  {
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;

    calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    emit SetPeriod(openingTime, closingTime);

    return true;
  }

  // bonus drop. Bonus tokens take a lock.
  function bonusDrop(
    address _beneficiary,
    uint256 _tokenAmount
  )
  external
  onlyOwner
    returns (bool)
  {
    _processPurchase(_beneficiary, _tokenAmount);

    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      0,
      _tokenAmount
    );

    _token.increaseLockBalance(_beneficiary, _tokenAmount);

    emit TokenLocked(
        _beneficiary,
        _tokenAmount
    );    

    return true;
  }

  // bonus drop. Bonus tokens are not locked !!!
  function unlockBonusDrop(
    address _beneficiary,
    uint256 _tokenAmount
  )
  external
    onlyOwner
    returns (bool)
  {
    _processPurchase(_beneficiary, _tokenAmount);

    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      0,
      _tokenAmount
    );

   

    return true;
  }

  // Increases the lock on the balance at a specific address.
  function increaseTokenLock(
    address _beneficiary,
    uint256 _tokenAmount
  )
    onlyOwner
    external
    returns (bool)
  {
    return(_token.increaseLockBalance(_beneficiary, _tokenAmount));
  }

  // Decreases the lock on the balance at a specific address.
  function decreaseTokenLock(
    address _beneficiary,
    uint256 _tokenAmount
  )
    onlyOwner
    external
    returns (bool)
  {
    return(_token.decreaseLockBalance(_beneficiary, _tokenAmount));
  }

  // It completely unlocks a specific address.
  function clearTokenLock(
    address _beneficiary
  )
    onlyOwner
    external
    returns (bool)
  {
    return(_token.clearLockBalance(_beneficiary));
  }

  // Redefine the point at which a lock that affects the whole is released.
  function resetLockReleaseTime(
    uint256 releaseTime
  )
    onlyOwner
    external
    returns (bool)
  {
    return(_token.setReleaseTime(releaseTime));
  }

  // Attention of administrator is required!! Migrate the owner of the token.
  function transferTokenOwnership(
    address _newOwner
  )
    onlyOwner
    external
    returns (bool)
  {
    _token.transferOwnership(_newOwner);
    return true;
  }

  // Stops the entire transaction of the token completely.
  function pauseToken()
    onlyOwner
    external
    returns (bool)
  {
    _token.pause();
    return true;
  }

  // Resume a suspended transaction.
  function unpauseToken()
    onlyOwner
    external
    returns (bool)
  {
    _token.unpause();
    return true;
  }
}
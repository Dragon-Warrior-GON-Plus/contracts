//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Interfaces/IBotPrevent.sol";// wanakafarm

contract GON is ERC20PresetMinterPauser {
    
    IBotPrevent public BP;
    bool public bpEnabled = false;
    uint256 public constant MAX_SUPPLY = 10 * (10 ** 6) * (10 ** 18);
    
    
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GON+: ADMIN role required");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "GON+: MINTER role required");
        _;
    }
    
    constructor() ERC20PresetMinterPauser("Token GON+", "GON+") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }
    
    
    function mint(address to, uint256 amount) public virtual override onlyMinter {
        require(totalSupply() + amount <= MAX_SUPPLY, "GON+: Max supply exceeded");
        _mint(to, amount);
    }
    
    function setBotPrevent(address _BP) external onlyAdmin {
        require(address(_BP) != address(0), "address BP is address zero");
        BP = IBotPrevent(_BP);
    }
    
    function enabledBP() external onlyAdmin {
        require(address(BP) != address(0), "address BP is address zero");
        bpEnabled = true;
    }
    
    function disableBP() external onlyAdmin {
        require(address(BP) != address(0), "address BP is address zero");
        bpEnabled = false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (bpEnabled) {
            uint256 botFee = BP.protect(sender, recipient, amount);
            super._transfer(sender, address(this), botFee);
            amount -= botFee;
        }
        super._transfer(sender, recipient, amount);
    }
    
    function getBalanceNavite() public view returns( uint256 ) {
        return address(this).balance;
    }

    function getBalanceToken(IERC20 _token) public view returns( uint256 ) {
        return _token.balanceOf(address(this));
    }
  
    function withdrawNative(uint256 _amount) public onlyAdmin {
        require(_amount > 0 , "_amount must be greater than 0");
        require( address(this).balance >= _amount ,"balanceOfNative:  is not enough");
        payable(msg.sender).transfer(_amount);
    }
    
  
    function withdrawToken(IERC20 _token, uint256 _amount) public onlyAdmin {
        require(_amount > 0 , "_amount must be greater than 0");
        require(_token.balanceOf(address(this)) >= _amount , "balanceOfToken:  is not enough");
        _token.transfer(msg.sender, _amount);
    }
    
    function withdrawNativeAll() public onlyAdmin {
        require(address(this).balance > 0 ,"balanceOfNative:  is equal 0");
        payable(msg.sender).transfer(address(this).balance);
    }
  
    function withdrawTokenAll(IERC20 _token) public onlyAdmin  {
        require(_token.balanceOf(address(this)) > 0 , "balanceOfToken:  is equal 0");
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
    
    function withdrawERC721(IERC721 _token, uint256[] memory _tokenIds) public onlyAdmin {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
           _token.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }
    }

    receive() external payable {
    }

}

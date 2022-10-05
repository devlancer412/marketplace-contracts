// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {ILSP7DigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {LSP8MarketplaceSale} from "./LSP8MarketplaceSale.sol";

contract LSP8MarketplacePrice is LSP8MarketplaceSale {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  // --- Storage.

  mapping(address => mapping(bytes32 => Prices)) private _prices;
  struct Prices {
    EnumerableSet.AddressSet LSP7Addresses;
    EnumerableMap.AddressToUintMap LSP7Amounts;
    uint256 LYXAmount;
  }

  // --- Modifiers.

  /**
   * Checks that there is no buyout amount for an LSP8 in a specific LSP7.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LSP7Address LSP7 address.
   *
   * @notice This modifier checks that there is no buyout price set
   * for `LSP8Address` in `LSP7Address` tokens.
   */
  modifier LSP7PriceDoesNotExist(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address
  ) {
    require(
      !_prices[LSP8Address][tokenId].LSP7Addresses.contains(LSP7Address),
      "There already exists a buyout price in this token. Try to change it."
    );
    _;
  }

  /**
   * Checks that there exists a buyout amount for an LSP8 in a specific LSP7.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LSP7Address LSP7 address.
   *
   * @notice This modifier checks that there exists a buyout price set
   * for `LSP8Address` in `LSP7Address` tokens.
   */
  modifier LSP7PriceDoesExist(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address
  ) {
    require(
      _prices[LSP8Address][tokenId].LSP7Addresses.contains(LSP7Address),
      "There is no buyout price in this token. Try to add one."
    );
    _;
  }

  /**
   * Checks that the amount of LYX sent is equal to the buyout price for the LSP8.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   *
   * @notice This modifier checks that the amout of Lyx sent
   * is equal with the buyout pice in LYX for `LSP8Address`.
   */
  modifier sendEnoughLYX(address LSP8Address, bytes32 tokenId) {
    require(_prices[LSP8Address][tokenId].LYXAmount == msg.value, "You didn't send enough LYX");
    _;
  }

  /**
   * Checks that sender has enough LSP7 tokens for buyout of LSP8.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LSP7Address LSP7 address.
   *
   * @notice This modifier checks that sender's balance in `LSP7Address`
   * is equal or greater than the buyout price in `LSP7Address` buyout
   * price for the LSP8.
   */
  modifier haveEnoughLSP7Balance(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address
  ) {
    require(
      ILSP7DigitalAsset(LSP7Address).balanceOf(msg.sender) >
        _prices[LSP8Address][tokenId].LSP7Amounts.get(LSP7Address),
      "Sender doesn't have enough token balance."
    );
    _;
  }

  /**
   * Checks that the LSP7 is among the buyout amounts of the LSP8.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LSP7Address LSP7 address.
   *
   * @notice This modifier checks that `LSP8Address` + `tokenId`
   * owner accepts buyout in `LSP7Address`.
   */
  modifier sellerAcceptsToken(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address
  ) {
    require(
      _prices[LSP8Address][tokenId].LSP7Addresses.contains(LSP7Address),
      "Seller does not accept this token."
    );
    _;
  }

  // --- LYX Price functionality.

  /**
   * Add LYX buyout amount.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LYXAmount Amount of LYX for buyout of LSP8.
   *
   * @notice Once called the method saves the amount of LYX
   * tokens needed to buy the LSP8.
   */
  function _addLYXPrice(
    address LSP8Address,
    bytes32 tokenId,
    uint256 LYXAmount
  ) internal {
    _prices[LSP8Address][tokenId].LYXAmount = LYXAmount;
  }

  /**
   * Remove LYX buyout amount.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   *
   * @notice Once called the method removes the amount of LYX
   * tokens needed to buy the LSP8.
   */
  function _removeLYXPrice(address LSP8Address, bytes32 tokenId) internal {
    delete _prices[LSP8Address][tokenId].LYXAmount;
  }

  /**
   * Returns LYX buyout amount.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   *
   * @return The amount of tokens needed to buy the LSP8.
   */
  function _returnLYXPrice(address LSP8Address, bytes32 tokenId) public view returns (uint256) {
    return _prices[LSP8Address][tokenId].LYXAmount;
  }

  // --- LSP7 Price functionality.

  /**
   * Add LSP7 buyout amounts.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LSP7Addresses Array of LSP7 addresses.
   * @param LSP7Amounts Array of LSP7 amounts.
   *
   * @notice Once called the method saves the array of addresses
   * `LSP7Addresses` and the array of amounts `LSP7Amounts` allowed
   * for to be traded for the LSP8.
   */
  function _addLSP7Prices(
    address LSP8Address,
    bytes32 tokenId,
    address[] memory LSP7Addresses,
    uint256[] memory LSP7Amounts
  ) internal {
    Prices storage _price = _prices[LSP8Address][tokenId];
    for (uint256 i = 0; i < LSP7Addresses.length; i++) {
      _price.LSP7Addresses.add(LSP7Addresses[i]);
      _price.LSP7Amounts.set(LSP7Addresses[i], LSP7Amounts[i]);
    }
  }

  /**
   * Add one LSP7 buyout amounta.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LSP7Address LSP7 address.
   * @param LSP7Amount LSP7 amount.
   *
   * @notice Once called the method saves the address `LSP7Address`
   * and the amount `LSP7Amount` that is allowed to be traded for the LSP8.
   */
  function _addLSP7PriceByAddress(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address,
    uint256 LSP7Amount
  ) internal {
    Prices storage _price = _prices[LSP8Address][tokenId];
    _price.LSP7Addresses.add(LSP7Address);
    _price.LSP7Amounts.set(LSP7Address, LSP7Amount);
  }

  /**
   * Return LSP7 prices for an LSP8.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   *
   * @return An array of LSP7 addresses and an array of token amounts.
   */
  function _returnLSP7Prices(address LSP8Address, bytes32 tokenId)
    public
    view
    returns (address[] memory, uint256[] memory)
  {
    Prices storage _price = _prices[LSP8Address][tokenId];
    uint256[] memory LSP7Amounts;
    for (uint256 i = 0; i < _price.LSP7Addresses.length(); i++) {
      LSP7Amounts[i] = _price.LSP7Amounts.get(_price.LSP7Addresses.at(i));
    }
    return (_price.LSP7Addresses.values(), LSP7Amounts);
  }

  /**
   * Return LSP7 price for an LSP8.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LSP7Address Address of the LSP7 token allowed for trade.
   *
   * @return The token amount needed for buyout of an LSP7 token.
   */
  function _returnLSP7PriceByAddress(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address
  ) internal view returns (uint256) {
    return _prices[LSP8Address][tokenId].LSP7Amounts.get(LSP7Address);
  }

  /**
   * Add one LSP7 buyout amounta.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   * @param LSP7Address LSP7 address.
   *
   * @notice Once called the method removes the address `LSP7Address`
   * and the amount `LSP7Amount` that is allowed to be traded for the LSP8.
   */
  function _removeLSP7PriceByAddress(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address
  ) internal {
    _prices[LSP8Address][tokenId].LSP7Addresses.remove(LSP7Address);
    _prices[LSP8Address][tokenId].LSP7Amounts.remove(LSP7Address);
  }

  /**
   * Add one LSP7 buyout amounta.
   *
   * @param LSP8Address Address of an existing LSP8 sale.
   * @param tokenId Token Id of an existing LSP8 on sale.
   *
   * @notice Once called the method removes all the prices for an LSP8.
   */
  function _removeLSP8Prices(address LSP8Address, bytes32 tokenId) internal {
    delete _prices[LSP8Address][tokenId];
  }
}

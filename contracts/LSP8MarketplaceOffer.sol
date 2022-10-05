// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {ILSP7DigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";
import {ILSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {LSP8MarketplaceSale} from "./LSP8MarketplaceSale.sol";

contract LSP8MarketplaceOffer is LSP8MarketplaceSale {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  // --- Storage

  mapping(address => mapping(bytes32 => Offers)) private _offers;
  struct Offers {
    EnumerableSet.AddressSet LSP8Addresses;
    mapping(address => EnumerableSet.Bytes32Set) LSP8TokenIds;
    EnumerableSet.AddressSet LSP7OfferCreators;
    mapping(address => EnumerableSet.AddressSet) LSP7Addresses;
    mapping(address => EnumerableMap.AddressToUintMap) LSP7Amounts;
    EnumerableSet.AddressSet LYXOfferCreators;
    EnumerableMap.AddressToUintMap LYXOffers;
  }

  // --- Modifiers.

  /**
   * Modifier checks if there are no offers with this LSP8.
   *
   * @param offerLSP8Address The address of the LSP8.
   * @param offerTokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
   *
   * @notice Once called the smart contract calls the `offerLSP8Address` smart contract's
   * method `isOperatorFor` which returns a boolean value. If there are no offers using this LSP8
   * the return falue must be false.
   */
  modifier LSP8OfferDoesNotExist(address offerLSP8Address, bytes32 offerTokenId) {
    require(
      !ILSP8IdentifiableDigitalAsset(offerLSP8Address).isOperatorFor(address(this), offerTokenId),
      "Offer already exists."
    );
    _;
  }

  /**
   * Modifier checks if there are offers with this LSP8.
   *
   * @param offerLSP8Address The address of the LSP8.
   * @param offerTokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
   *
   * @notice Once called the smart contract calls the `offerLSP8Address` smart contract's
   * method `isOperatorFor` which returns a boolean value. If there is an offer with this LSP8
   * the return falue must be true.
   */
  modifier LSP8OfferExists(address offerLSP8Address, bytes32 offerTokenId) {
    require(
      ILSP8IdentifiableDigitalAsset(offerLSP8Address).isOperatorFor(address(this), offerTokenId),
      "Offer does not exist."
    );
    _;
  }

  /**
   * Modifier checks if there is an offer for a specific `LSP8Address` and `tokenId`
   * with the `offerLSP8Address` and `offerTokenId`.
   *
   * @param LSP8Address The address of the LSP8.
   * @param tokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
   * @param offerLSP8Address The address of the offer LSP8.
   * @param offerTokenId Token id of the `offerLSP8Address` LSP8 that is about to be checked.
   *
   * @notice Once called the method checks if there is an offer to `LSP8Address` and `tokenId`
   * from `offerLSP8Address` and `offerTokenId`.
   */
  modifier LSP8OfferExistsForThisLSP8(
    address LSP8Address,
    bytes32 tokenId,
    address offerLSP8Address,
    bytes32 offerTokenId
  ) {
    require(
      _offers[LSP8Address][tokenId].LSP8TokenIds[offerLSP8Address].contains(offerTokenId),
      "Offer does not exist for this LSP8."
    );
    _;
  }

  /**
   * Checks that sender has enough LSP7 tokens for creating an offer.
   *
   * @param LSP7Address LSP7 address.
   * @param LSP7Amount LSP7 address.
   *
   * @notice Checks that sender's balance in `LSP7Address`
   * is equal or greater than the `LSP7Amount`.
   */
  modifier haveEnoughLSP7BalanceForOffer(address LSP7Address, uint256 LSP7Amount) {
    require(
      ILSP7DigitalAsset(LSP7Address).balanceOf(msg.sender) > LSP7Amount,
      "Sender doesn't have enough token balance."
    );
    _;
  }

  /**
   * Checks that offer creator has enough LSP7 tokens.
   *
   * @param LSP7Address LSP7 address.
   * @param offerCreator LSP7 offer creator.
   *
   * @notice Checks that `offerCreator`'s balance in `LSP7Address`
   * is equal or greater than the offered amount.
   */
  modifier offerCreatorHasEnoughLSP7Balance(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address,
    address offerCreator
  ) {
    require(
      ILSP7DigitalAsset(LSP7Address).balanceOf(msg.sender) >
        _offers[LSP8Address][tokenId].LSP7Amounts[offerCreator].get(LSP7Address),
      "Sender doesn't have enough token balance."
    );
    _;
  }

  /**
   * Checks if the offer exists adn is owned by the sender.
   *
   * @param LSP8Address LSP8 address.
   * @param tokenId LSP8 token id.
   * @param LSP7Address LSP7 address.
   */
  modifier LSP7OfferExists(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address,
    address offerCreator
  ) {
    require(
      _offers[LSP8Address][tokenId].LSP7Amounts[offerCreator].contains(LSP7Address),
      "This offer doesn't exist or you aren't the owner."
    );
    _;
  }

  // --- Offer functionality.

  /**
   * Create an offer to trade LSP8 for LSP8
   *
   * @param LSP8Address The address of the LSP8 that will receive an offer.
   * @param tokenId Token id of the `LSP8Address` LSP8.
   * @param offerLSP8Address The address of the LSP8 that will be offered in exchange.
   * @param offerTokenId Token id of the `offerLSP8Address` LSP8.
   *
   * @notice Once this method is called the `offerLSP8Address` will be added to an
   * array of addresses that contains the addresses of all the LSP8s offered for exchange.
   * After that the method creates an array for the `offerLSP8Address` which keeps track
   * of all the token ids that are offered in exchange to `LSP8Address`+`tokenId`.
   */
  function _makeLSP8Offer(
    address LSP8Address,
    bytes32 tokenId,
    address offerLSP8Address,
    bytes32 offerTokenId
  ) internal {
    Offers storage _offer = _offers[LSP8Address][tokenId];
    _offer.LSP8Addresses.add(offerLSP8Address);
    _offer.LSP8TokenIds[offerLSP8Address].add(offerTokenId);
    ILSP8IdentifiableDigitalAsset(offerLSP8Address).authorizeOperator(address(this), offerTokenId);
  }

  /**
   * Remove an trade offer from an LSP8.
   *
   * @param LSP8Address The address of the LSP8 that will have an offer removed.
   * @param tokenId Token id of the `LSP8Address` LSP8.
   * @param offerLSP8Address The address of the LSP8 that will be removed from offers.
   * @param offerTokenId Token id of the `offerLSP8Address` LSP8.
   *
   * @notice Once this method is called the `offerLSP8Address` will be removed from an
   * array of addresses that contains the addresses of all the LSP8s offered for exchange.
   * After that the method removes the `offerTokenId` from the array of token ids
   * from `offerLSP8Address` which keeps track of all the token ids that are offered
   * in exchange to `LSP8Address`+`tokenId`.
   */
  function _removeLSP8Offer(
    address LSP8Address,
    bytes32 tokenId,
    address offerLSP8Address,
    bytes32 offerTokenId
  ) internal {
    _offers[LSP8Address][tokenId].LSP8Addresses.remove(offerLSP8Address);
    _offers[LSP8Address][tokenId].LSP8TokenIds[offerLSP8Address].remove(offerTokenId);
    ILSP8IdentifiableDigitalAsset(offerLSP8Address).revokeOperator(address(this), offerTokenId);
  }

  /**
   * Return all the addresses that are offered for an LSP8.
   *
   * @param LSP8Address The address of the LSP8.
   * @param tokenId Token id of the `LSP8Address` LSP8.
   *
   * @return An array of addresses.
   *
   * @notice This method returns an array containing all the addresses
   * that are registred as trade offers for a specific `LSP8Address` and `tokenId`.
   */
  function _returnLSP8OfferAddresses(address LSP8Address, bytes32 tokenId)
    public
    view
    returns (address[] memory)
  {
    return _offers[LSP8Address][tokenId].LSP8Addresses.values();
  }

  /**
   * Return all the token ids of a `offerLSP8Addresss` that are offered for an LSP8.
   *
   * @param LSP8Address The address of the LSP8.
   * @param tokenId Token id of the `LSP8Address` LSP8.
   * @param offerLSP8Address The address of the LSP8 that is offered in exchange for the `LSP8Address` LSP8.
   *
   * @return An array of bytes32 token ids.
   *
   * @notice This method returns an array containing all the token ids belonging
   * to the `offerLSP8Address` LSP8 that are registred as trade offers for
   * a specific `LSP8Address` and `tokenId`.
   */
  function _returnLSP8OfferTokenIdsByAddress(
    address LSP8Address,
    bytes32 tokenId,
    address offerLSP8Address
  ) public view returns (bytes32[] memory) {
    Offers storage _offer = _offers[LSP8Address][tokenId];
    bytes32[] memory LSP8TokenIds;
    for (uint256 i = 0; i < _offer.LSP8TokenIds[offerLSP8Address].length(); i++) {
      LSP8TokenIds[i] = _offer.LSP8TokenIds[offerLSP8Address].at(i);
    }
    return LSP8TokenIds;
  }

  /**
   * Create LSP7 offer.
   *
   * @param LSP8Address LSP8 address.
   * @param tokenId LSP8 token id.
   * @param LSP7Address Address of the LSP7 offer.
   * @param LSP7Amount The amount of tokens offered.
   *
   * @notice Creates an offer and saves the address and the amount of tokens offered.
   * If the creator of that offer has no more offers, it saves his address to
   * the array as well.
   */
  function _makeLSP7Offer(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address,
    uint256 LSP7Amount
  ) internal {
    Offers storage _offer = _offers[LSP8Address][tokenId];
    if (_offer.LSP7Amounts[msg.sender].contains(LSP7Address)) {
      _offer.LSP7Amounts[msg.sender].remove(LSP7Address);
      _offer.LSP7Amounts[msg.sender].set(LSP7Address, LSP7Amount);
    } else {
      _offer.LSP7Addresses[msg.sender].add(LSP7Address);
      _offer.LSP7Amounts[msg.sender].set(LSP7Address, LSP7Amount);
    }
    ILSP7DigitalAsset(LSP7Address).authorizeOperator(address(this), LSP7Amount);
    if (_offer.LSP7Addresses[msg.sender].length() > 0) {
      _offer.LSP7OfferCreators.add(msg.sender);
    }
  }

  /**
   * Remove LSP7 offer.
   *
   * @param LSP8Address LSP8 address.
   * @param tokenId LSP8 token id.
   * @param LSP7Address Address of the LSP7 offer.
   *
   * @notice Removes an offer address and the amount of tokens offered.
   * If the creator of that offer has no more offers, it removes his address from
   * the array as well.
   */
  function _removeLSP7Offer(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address
  ) internal {
    Offers storage _offer = _offers[LSP8Address][tokenId];
    _offer.LSP7Addresses[msg.sender].remove(LSP7Address);
    _offer.LSP7Amounts[msg.sender].remove(LSP7Address);
    ILSP7DigitalAsset(LSP7Address).revokeOperator(address(this));
    if (_offer.LSP7Addresses[msg.sender].length() == 0) {
      _offer.LSP7OfferCreators.remove(msg.sender);
    }
  }

  /**
   * Return LSP7 offer creators.
   *
   * @param LSP8Address LSP8 address.
   * @param tokenId LSP8 token id.
   *
   * @return An array of addresses of the LSP7 offer creators.
   */
  function _returnLSP7OfferCreators(address LSP8Address, bytes32 tokenId)
    public
    view
    returns (address[] memory)
  {
    return _offers[LSP8Address][tokenId].LSP7OfferCreators.values();
  }

  /**
   * return LSP7 offers by offer creators.
   *
   * @param LSP8Address LSP8 address.
   * @param tokenId LSP8 token id.
   * @param offersCreator Address of the owner of the LSP7 offers.
   *
   * @return Two arrays, first with LSP7 addresses
   * second with LSP7 amount.
   */
  function _returnLSP7OffersByCreators(
    address LSP8Address,
    bytes32 tokenId,
    address offersCreator
  ) public view returns (address[] memory, uint256[] memory) {
    Offers storage _offer = _offers[LSP8Address][tokenId];
    uint256[] memory LSP7Amounts;
    for (uint256 i; i < _offer.LSP7Addresses[offersCreator].length(); i++) {
      LSP7Amounts[i] = _offer.LSP7Amounts[offersCreator].get(
        _offer.LSP7Addresses[offersCreator].at(i)
      );
    }
    return (_offer.LSP7Addresses[offersCreator].values(), LSP7Amounts);
  }

  /**
   * Returns LSP7 offer amount.
   *
   * @param LSP8Address LSP8 address.
   * @param tokenId LSP8 token id.
   * @param LSP7Address LSP7 address.
   * @param offerCreator Address of the owner of the LSP7 offers.
   *
   * @return LSP7 offer amount
   */
  function _returnLSP7OfferAmount(
    address LSP8Address,
    bytes32 tokenId,
    address LSP7Address,
    address offerCreator
  ) public view returns (uint256) {
    return _offers[LSP8Address][tokenId].LSP7Amounts[offerCreator].get(LSP7Address);
  }

  /**
   * Create a LYX offer.
   *
   * @param LSP8Address LSP8 address
   * @param tokenId LSP8 token id
   * @param amount The amount of LYX offered.
   *
   * @notice Creates an offer and saves the amount of tokens offered.
   * Saves his address to the array as well.
   */
  function _makeLYXOffer(
    address LSP8Address,
    bytes32 tokenId,
    uint256 amount
  ) internal {
    Offers storage _offer = _offers[LSP8Address][tokenId];
    if (_offer.LYXOffers.contains(msg.sender)) {
      _offer.LYXOffers.remove(msg.sender);
      _offer.LYXOffers.set(msg.sender, amount);
    } else {
      _offer.LYXOfferCreators.add(msg.sender);
      _offer.LYXOffers.set(msg.sender, amount);
    }
  }

  /**
   * Remove a LYX offer.
   *
   * @param LSP8Address LSP8 address
   * @param tokenId LSP8 token id
   *
   * @notice Removes an offer by deleting the offer creator
   * and the amount of LYX ofLYX offered.
   */
  function _removeLYXOffer(address LSP8Address, bytes32 tokenId) internal {
    _offers[LSP8Address][tokenId].LYXOffers.remove(msg.sender);
  }

  /**
   * Returns LYX offers.
   *
   * @param LSP8Address LSP8 address
   * @param tokenId LSP8 token id
   *
   * @return Two arrays first contains the addresses of the LYX offers creators
   * and second array contains the amounts of LYX offered.
   */
  function _returnLYXOffers(address LSP8Address, bytes32 tokenId)
    public
    view
    returns (address[] memory, uint256[] memory)
  {
    Offers storage _offer = _offers[LSP8Address][tokenId];
    uint256[] memory LYXAmounts;
    for (uint256 i; i < _offer.LYXOfferCreators.length(); i++) {
      LYXAmounts[i] = _offer.LYXOffers.get(_offer.LYXOfferCreators.at(i));
    }

    return (_offers[LSP8Address][tokenId].LYXOfferCreators.values(), LYXAmounts);
  }

  /**
   * Remove all offers of a LSP8.
   *
   * @param LSP8Address The address of the LSP8 that will have the offers removed.
   * @param tokenId Token id of the `LSP8Address` LSP8.
   *
   * @notice Removes all the offers that exist for the `LSP8Address` with `tokenId`.
   */
  function _removeOffers(address LSP8Address, bytes32 tokenId) internal {
    delete _offers[LSP8Address][tokenId];
  }
}

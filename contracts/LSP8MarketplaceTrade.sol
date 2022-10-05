// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {ILSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import {ILSP7DigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";
import {LSP8MarketplaceSale} from "./LSP8MarketplaceSale.sol";

contract LSP8MarketplaceTrade {
  // --- UniversalReciever data generator.

  /**
   * This method creates data used for universalReciever (LSP0).
   *
   * @param from The sender of the LSP7/LSP8
   * @param to The receiver of the LSP7/LSP8
   * @param amount Amount of LSP7/LSP8 tokens sent.
   *
   * @return A bytes variable used for transfer data.
   */
  function _returnLSPTransferData(
    address from,
    address to,
    uint256 amount
  ) internal pure returns (bytes memory) {
    return
      abi.encodeWithSignature(
        "universalReceiver(bytes32 typeId, bytes memory data)",
        keccak256("TOKEN_RECEIVE"),
        abi.encodePacked(from, to, amount)
      );
  }

  // --- LSP8 and LSP7 transfer functions.

  /**
   * Transfer LSP8.
   *
   * @param LSP8Address Address of the LSP8 to be transfered.
   * @param from Address of the LSP8 sender.
   * @param to Address of the LSP8 receiver.
   * @param tokenId Token id of the LSP8 to be transfered.
   * @param force False if the receiver has universalReceiver implementation.
   * @param amount Amount of LSP8 to be transfered.
   *
   * @notice For more information about this mathid check
   * the `transfer` method from LSP8.
   */
  function _transferLSP8(
    address LSP8Address,
    address from,
    address to,
    bytes32 tokenId,
    bool force,
    uint256 amount
  ) internal {
    ILSP8IdentifiableDigitalAsset(LSP8Address).transfer(
      from,
      to,
      tokenId,
      force,
      _returnLSPTransferData(from, to, amount)
    );
  }

  /**
   * Transfer LSP7.
   *
   * @param LSP7Address Address of the LSP7 to be transfered.
   * @param from Address of theLSP7 sender.
   * @param to Address of the LSP8 receiver.
   * @param force False if the receiver has universalReceiver implementation.
   * @param amount Amount of LSP7 to be transfered.
   *
   * @notice For more information about this mathid check
   * the `transfer` method from LSP7.
   */
  function _transferLSP7(
    address LSP7Address,
    address from,
    address to,
    uint256 amount,
    bool force
  ) internal {
    ILSP7DigitalAsset(LSP7Address).authorizeOperator(address(this), amount);
    ILSP7DigitalAsset(LSP7Address).transfer(
      from,
      to,
      amount,
      force,
      _returnLSPTransferData(from, to, amount)
    );
  }
}

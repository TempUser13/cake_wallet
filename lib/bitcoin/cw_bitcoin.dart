part of 'bitcoin.dart';

class CWBitcoin extends Bitcoin {
  @override
  TransactionPriority getMediumTransactionPriority() => BitcoinTransactionPriority.medium;

  @override
  WalletCredentials createBitcoinRestoreWalletFromSeedCredentials(
          {required String name, required String mnemonic, required String password}) =>
      BitcoinRestoreWalletFromSeedCredentials(name: name, mnemonic: mnemonic, password: password);

  @override
  WalletCredentials createBitcoinRestoreWalletFromWIFCredentials(
          {required String name,
          required String password,
          required String wif,
          WalletInfo? walletInfo}) =>
      BitcoinRestoreWalletFromWIFCredentials(
          name: name, password: password, wif: wif, walletInfo: walletInfo);

  @override
  WalletCredentials createBitcoinNewWalletCredentials(
          {required String name, WalletInfo? walletInfo}) =>
      BitcoinNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  List<String> getWordList() => wordlist;

  @override
  Map<String, String> getWalletKeys(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    final keys = bitcoinWallet.keys;

    return <String, String>{
      'wif': keys.wif,
      'privateKey': keys.privateKey,
      'publicKey': keys.publicKey
    };
  }

  @override
  List<TransactionPriority> getTransactionPriorities() => BitcoinTransactionPriority.all;

  @override
  List<TransactionPriority> getLitecoinTransactionPriorities() => LitecoinTransactionPriority.all;

  @override
  TransactionPriority deserializeBitcoinTransactionPriority(int raw) =>
      BitcoinTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority deserializeLitecoinTransactionPriority(int raw) =>
      LitecoinTransactionPriority.deserialize(raw: raw);

  @override
  int getFeeRate(Object wallet, TransactionPriority priority) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.feeRate(priority);
  }

  @override
  Future<void> generateNewAddress(Object wallet, String label) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.walletAddresses.generateNewAddress(label: label);
    await wallet.save();
  }

  @override
  Future<void> updateAddress(Object wallet, String address, String label) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    bitcoinWallet.walletAddresses.updateAddress(address, label);
    await wallet.save();
  }

  @override
  Object createBitcoinTransactionCredentials(List<Output> outputs,
      {required TransactionPriority priority, int? feeRate}) {
    final bitcoinFeeRate =
        priority == BitcoinTransactionPriority.custom && feeRate != null ? feeRate : null;
    return BitcoinTransactionCredentials(
        outputs
            .map((out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount,
                memo: out.memo))
            .toList(),
        priority: priority as BitcoinTransactionPriority,
        feeRate: bitcoinFeeRate);
  }

  @override
  Object createBitcoinTransactionCredentialsRaw(List<OutputInfo> outputs,
          {TransactionPriority? priority, required int feeRate}) =>
      BitcoinTransactionCredentials(outputs,
          priority: priority != null ? priority as BitcoinTransactionPriority : null,
          feeRate: feeRate);

  @override
  List<String> getAddresses(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.walletAddresses.addressesByReceiveType
        .map((BaseBitcoinAddressRecord addr) => addr.address)
        .toList();
  }

  @override
  @computed
  List<ElectrumSubAddress> getSubAddresses(Object wallet) {
    final electrumWallet = wallet as ElectrumWallet;
    return electrumWallet.walletAddresses.addressesByReceiveType
        .map((BaseBitcoinAddressRecord addr) => ElectrumSubAddress(
            id: addr.index,
            name: addr.name,
            address: addr.address,
            txCount: addr.txCount,
            balance: addr.balance,
            isChange: addr.isHidden))
        .toList();
  }

  @override
  Future<int> estimateFakeSendAllTxAmount(Object wallet, TransactionPriority priority) async {
    try {
      final sk = ECPrivate.random();
      final electrumWallet = wallet as ElectrumWallet;

      if (wallet.type == WalletType.bitcoinCash) {
        final p2pkhAddr = sk.getPublic().toP2pkhAddress();
        final estimatedTx = await electrumWallet.estimateSendAllTx(
          [BitcoinOutput(address: p2pkhAddr, value: BigInt.zero)],
          getFeeRate(wallet, priority as BitcoinCashTransactionPriority),
        );

        return estimatedTx.amount;
      }

      final p2shAddr = sk.getPublic().toP2pkhInP2sh();
      final estimatedTx = await electrumWallet.estimateSendAllTx(
        [BitcoinOutput(address: p2shAddr, value: BigInt.zero)],
        getFeeRate(
          wallet,
          wallet.type == WalletType.litecoin
              ? priority as LitecoinTransactionPriority
              : priority as BitcoinTransactionPriority,
        ),
      );

      return estimatedTx.amount;
    } catch (_) {
      return 0;
    }
  }

  @override
  String getAddress(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.walletAddresses.address;
  }

  @override
  String formatterBitcoinAmountToString({required int amount}) =>
      bitcoinAmountToString(amount: amount);

  @override
  double formatterBitcoinAmountToDouble({required int amount}) =>
      bitcoinAmountToDouble(amount: amount);

  @override
  int formatterStringDoubleToBitcoinAmount(String amount) => stringDoubleToBitcoinAmount(amount);

  @override
  String bitcoinTransactionPriorityWithLabel(TransactionPriority priority, int rate,
          {int? customRate}) =>
      (priority as BitcoinTransactionPriority).labelWithRate(rate, customRate);

  @override
  List<BitcoinUnspent> getUnspents(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.unspentCoins;
  }

  Future<void> updateUnspents(Object wallet) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.updateAllUnspents();
  }

  WalletService createBitcoinWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return BitcoinWalletService(walletInfoSource, unspentCoinSource);
  }

  WalletService createLitecoinWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return LitecoinWalletService(walletInfoSource, unspentCoinSource);
  }

  @override
  TransactionPriority getBitcoinTransactionPriorityMedium() => BitcoinTransactionPriority.medium;

  @override
  TransactionPriority getBitcoinTransactionPriorityCustom() => BitcoinTransactionPriority.custom;

  @override
  TransactionPriority getLitecoinTransactionPriorityMedium() => LitecoinTransactionPriority.medium;

  @override
  TransactionPriority getBitcoinTransactionPrioritySlow() => BitcoinTransactionPriority.slow;

  @override
  TransactionPriority getLitecoinTransactionPrioritySlow() => LitecoinTransactionPriority.slow;

  @override
  Future<void> setAddressType(Object wallet, dynamic option) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.walletAddresses.setAddressType(option as BitcoinAddressType);
  }

  @override
  BitcoinReceivePageOption getSelectedAddressType(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return BitcoinReceivePageOption.fromType(bitcoinWallet.walletAddresses.addressPageType);
  }

  @override
  bool hasSelectedSilentPayments(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.walletAddresses.addressPageType == SilentPaymentsAddresType.p2sp;
  }

  @override
  List<BitcoinReceivePageOption> getBitcoinReceivePageOptions() => BitcoinReceivePageOption.all;

  @override
  BitcoinAddressType getBitcoinAddressType(ReceivePageOption option) {
    switch (option) {
      case BitcoinReceivePageOption.p2pkh:
        return P2pkhAddressType.p2pkh;
      case BitcoinReceivePageOption.p2sh:
        return P2shAddressType.p2wpkhInP2sh;
      case BitcoinReceivePageOption.p2tr:
        return SegwitAddresType.p2tr;
      case BitcoinReceivePageOption.p2wsh:
        return SegwitAddresType.p2wsh;
      case BitcoinReceivePageOption.p2wpkh:
      default:
        return SegwitAddresType.p2wpkh;
    }
  }

  @override
  bool hasTaprootInput(PendingTransaction pendingTransaction) {
    return (pendingTransaction as PendingBitcoinTransaction).hasTaprootInputs;
  }

  @override
  Future<PendingBitcoinTransaction> replaceByFee(
      Object wallet, String transactionHash, String fee) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    return await bitcoinWallet.replaceByFee(transactionHash, int.parse(fee));
  }

  @override
  Future<bool> canReplaceByFee(Object wallet, String transactionHash) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.canReplaceByFee(transactionHash);
  }

  @override
  Future<bool> isChangeSufficientForFee(Object wallet, String txId, String newFee) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.isChangeSufficientForFee(txId, int.parse(newFee));
  }

  @override
  int getFeeAmountForPriority(
      Object wallet, TransactionPriority priority, int inputsCount, int outputsCount,
      {int? size}) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.feeAmountForPriority(
        priority as BitcoinTransactionPriority, inputsCount, outputsCount);
  }

  @override
  int getFeeAmountWithFeeRate(Object wallet, int feeRate, int inputsCount, int outputsCount,
      {int? size}) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.feeAmountWithFeeRate(
      feeRate,
      inputsCount,
      outputsCount,
    );
  }

  @override
  List<BitcoinSilentPaymentAddressRecord> getSilentPaymentAddresses(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.walletAddresses.silentAddresses
        .where((addr) => addr.type != SegwitAddresType.p2tr)
        .toList();
  }

  @override
  List<BitcoinSilentPaymentAddressRecord> getSilentPaymentReceivedAddresses(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.walletAddresses.silentAddresses
        .where((addr) => addr.type == SegwitAddresType.p2tr)
        .toList();
  }

  @override
  bool isBitcoinReceivePageOption(ReceivePageOption option) {
    return option is BitcoinReceivePageOption;
  }

  @override
  BitcoinAddressType getOptionToType(ReceivePageOption option) {
    return (option as BitcoinReceivePageOption).toType();
  }

  @override
  @computed
  bool getScanningActive(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.silentPaymentsScanningActive;
  }

  @override
  Future<void> setScanningActive(Object wallet, bool active) async {
    final bitcoinWallet = wallet as ElectrumWallet;

    // TODO: always when setting to scanning active, will force switch nodes. Remove when not needed anymore
    if (!getNodeIsCakeElectrs(wallet)) {
      final node = Node(
        useSSL: false,
        uri: '198.58.111.154:${(wallet.network == BitcoinNetwork.testnet ? 50002 : 50001)}',
      );
      node.type = WalletType.bitcoin;

      await bitcoinWallet.connectToNode(node: node);
    }

    bitcoinWallet.setSilentPaymentsScanning(active);
  }

  @override
  bool isTestnet(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.isTestnet ?? false;
  }

  @override
  int getHeightByDate({required DateTime date}) => getBitcoinHeightByDate(date: date);

  @override
  Future<void> rescan(Object wallet, {required int height, bool? doSingleScan}) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    // TODO: always when setting to scanning active, will force switch nodes. Remove when not needed anymore
    if (!getNodeIsCakeElectrs(wallet)) {
      final node = Node(
        useSSL: false,
        uri: '198.58.111.154:${(wallet.network == BitcoinNetwork.testnet ? 50002 : 50001)}',
      );
      node.type = WalletType.bitcoin;
      await bitcoinWallet.connectToNode(node: node);
    }
    bitcoinWallet.rescan(height: height, doSingleScan: doSingleScan);
  }

  @override
  bool getNodeIsCakeElectrs(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    final node = bitcoinWallet.node;

    return node?.uri.host == '198.58.111.154' &&
        node?.uri.port == (wallet.network == BitcoinNetwork.testnet ? 50002 : 50001);
  }

  @override
  void deleteSilentPaymentAddress(Object wallet, String address) {
    final bitcoinWallet = wallet as ElectrumWallet;
    bitcoinWallet.walletAddresses.deleteSilentPaymentAddress(address);
  }

  @override
  Future<void> updateFeeRates(Object wallet) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.updateFeeRates();
  }
}

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/cake_pay/cake_pay_service.dart';
import 'package:cake_wallet/cake_pay/cake_pay_card.dart';
import 'package:mobx/mobx.dart';
import 'package:device_display_brightness/device_display_brightness.dart';

part 'ionia_gift_card_details_view_model.g.dart';

class IoniaGiftCardDetailsViewModel = IoniaGiftCardDetailsViewModelBase
    with _$IoniaGiftCardDetailsViewModel;

abstract class IoniaGiftCardDetailsViewModelBase with Store {
  IoniaGiftCardDetailsViewModelBase({required this.ioniaService, required this.giftCard})
      : redeemState = InitialExecutionState(),
        remainingAmount = giftCard.remainingAmount,
        brightness = 0;

  final CakePayService ioniaService;

  double brightness;

  @observable
  IoniaGiftCard giftCard;

  @observable
  double remainingAmount;

  @observable
  ExecutionState redeemState;

  @action
  Future<void> redeem() async {
    giftCard.remainingAmount = remainingAmount;
    try {
      redeemState = IsExecutingState();
      await ioniaService.redeem(giftCardId: giftCard.id, amount: giftCard.remainingAmount);
      giftCard = await ioniaService.getGiftCard(id: giftCard.id);
      redeemState = ExecutedSuccessfullyState();
    } catch (e) {
      redeemState = FailureState(e.toString());
    }
  }

  @action
  Future<void> refeshCard() async {
     giftCard = await ioniaService.getGiftCard(id: giftCard.id);
     remainingAmount = giftCard.remainingAmount;
  }

  void increaseBrightness() async {
    brightness = await DeviceDisplayBrightness.getBrightness();
    await DeviceDisplayBrightness.setBrightness(1.0);
  }
}

$(function() {
  $('input.money.brl').maskMoney({
    thousands: '.',
    decimal: ',',
    precision: 2,
    allowZero: true
  });
});

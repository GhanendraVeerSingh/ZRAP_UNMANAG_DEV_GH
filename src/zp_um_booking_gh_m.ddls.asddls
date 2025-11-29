@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Projection entity'
@Metadata.allowExtensions: true
define view entity ZP_UM_BOOKING_GH_M
as projection on ZI_UM_BOOKING_GH_M
{
    key TravelId,
    key BookingId,
    BookingDate,
    @ObjectModel.text.element: [ 'CustomerName' ]
    CustomerId,
    _cust.LastName as CustomerName,
    @ObjectModel.text.element: [ 'CarrierName' ]
    AirlineID,
    _carrier.Name as CarrierName,
    ConnectionId,
    FlightDate,
    FlightPrice,
    CurrencyCode,
    /* Associations */
    _carrier,
    _conn,
    _cust,
    _travel : redirected to parent ZP_UM_TRAVEL_GH_M
}

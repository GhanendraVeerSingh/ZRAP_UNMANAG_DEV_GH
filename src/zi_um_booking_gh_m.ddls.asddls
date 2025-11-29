@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Interface view entity'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_UM_BOOKING_GH_M as select from /dmo/booking as Booking
association to parent ZI_UM_TRAVEL_GH_M as _travel on $projection.TravelId = _travel.TravelId
association [1..1] to /DMO/I_Customer as _cust on $projection.CustomerId = _cust.CustomerID
association [1..1] to /DMO/I_Carrier as _carrier on $projection.AirlineID = _carrier.AirlineID
association [1..1] to /DMO/I_Connection as _conn on $projection.AirlineID = _conn.AirlineID
                                                 and $projection.ConnectionId = _conn.ConnectionID
{
   key Booking.travel_id as TravelId,
   key Booking.booking_id as BookingId,
   Booking.booking_date as BookingDate,
   Booking.customer_id as CustomerId,
   Booking.carrier_id as AirlineID,
   Booking.connection_id as ConnectionId,
   Booking.flight_date as FlightDate,
   @Semantics.amount.currencyCode: 'CurrencyCode'
   Booking.flight_price as FlightPrice,
   Booking.currency_code as CurrencyCode ,
// -------- Association ----------
   _travel,
   _carrier,
   _conn,
   _cust
}

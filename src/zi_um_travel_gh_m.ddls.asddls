@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel : Root Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_UM_TRAVEL_GH_M as select from /dmo/travel as Travel
composition [0..*] of ZI_UM_BOOKING_GH_M as _booking 
association [0..1] to /DMO/I_Agency as _agency on $projection.AgencyId = _agency.AgencyID
association [0..1] to /DMO/I_Customer as _cust on $projection.CustomerId = _cust.CustomerID
association [0..1] to I_Currency as _curr on $projection.CurrencyCode = _curr.Currency
association [1..1] to /DMO/I_Travel_Status_VH as _overallstatus on $projection.Status = _overallstatus.TravelStatus
{
    
   key Travel.travel_id as TravelId,
   Travel.agency_id as AgencyId,
   Travel.customer_id as CustomerId,
   Travel.begin_date as BeginDate,
   Travel.end_date as EndDate,
   @Semantics.amount.currencyCode: 'CurrencyCode'
   Travel.booking_fee as BookingFee,
   @Semantics.amount.currencyCode: 'CurrencyCode'
   Travel.total_price as TotalPrice,
   Travel.currency_code as CurrencyCode,
   Travel.description as Description,
   Travel.status as Status,
   Travel.createdby as Createdby,
   Travel.createdat as Createdat,
//   @Semantics.systemDateTime.lastChangedAt: true
   Travel.lastchangedby as Lastchangedby,
   lastchangedat as Lastchangedat,
// ----- Associations--------
   _booking,
   _agency,
   _cust,
   _curr,
   _overallstatus
}

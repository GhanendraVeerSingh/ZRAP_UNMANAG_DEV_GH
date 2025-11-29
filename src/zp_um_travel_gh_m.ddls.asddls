@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel : Projection Root Entity'
@Metadata.allowExtensions: true

define root view entity ZP_UM_TRAVEL_GH_M provider contract transactional_query
as projection on ZI_UM_TRAVEL_GH_M
{
    key TravelId,
    @ObjectModel.text.element: [ 'agencyName' ]
    AgencyId,
    _agency.Name as agencyName,
    @ObjectModel.text.element: [ 'customerName' ]
    CustomerId,
    _cust.LastName as customerName,
    BeginDate,
    EndDate,
    BookingFee,
    TotalPrice,
    CurrencyCode,
    Description,
    @ObjectModel.text.element: [ 'statusText' ]
    Status,
    _overallstatus._Text.TravelStatus as statusText : localized,
    Createdby,
    Createdat,
    Lastchangedby,
    Lastchangedat,
    /* Associations */
    _agency,
    _booking : redirected to composition child ZP_UM_BOOKING_GH_M,
    _curr,
    _cust,
    _overallstatus
}

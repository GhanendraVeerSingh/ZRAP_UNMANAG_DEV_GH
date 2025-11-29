CLASS lsc_ZI_UM_TRAVEL_GH_M DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

* Method Definition to adjust the primary key fields specially in case of late numbering
    METHODS adjust_numbers REDEFINITION.

* Method Definition to Save the changes to database
    METHODS save REDEFINITION.

* Method Definition for cleanup of transactional buffer
    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_UM_TRAVEL_GH_M IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD adjust_numbers.
    DATA: wtl_mapped          TYPE /dmo/if_flight_legacy=>tt_ln_travel_mapping,
          wtl_booking_mapping TYPE /dmo/if_flight_legacy=>tt_ln_booking_mapping.
* Invoking FM to adjust travel number
    CALL FUNCTION '/DMO/FLIGHT_TRAVEL_ADJ_NUMBERS'
      IMPORTING
        et_travel_mapping  = wtl_mapped
        et_booking_mapping = wtl_booking_mapping
*       et_bookingsuppl_mapping =
      .

* To populate the mapped table for travel
    mapped-travel = VALUE #( FOR wel_mapped IN wtl_mapped
                              ( %tmp-TravelId = wel_mapped-preliminary-travel_id
                                TravelId = wel_mapped-final-travel_id ) ).

* To populate the mapped table for Booking
    mapped-booking = VALUE #( FOR wel_booking_mapping IN wtl_booking_mapping
                              ( %tmp-TravelId = wel_booking_mapping-preliminary-travel_id
                                %tmp-BookingId = wel_booking_mapping-preliminary-booking_id
                                TravelId = wel_booking_mapping-final-travel_id
                                BookingId = wel_booking_mapping-final-booking_id ) ).
  ENDMETHOD.

* Method Implementation to Save the changes to database
  METHOD save.
* Invoking FM to save the data
    CALL FUNCTION '/DMO/FLIGHT_TRAVEL_SAVE'.
  ENDMETHOD.

* Method Implementation for Transactional buffer cleanup.
  METHOD cleanup.
* Invoking FM for cleanup of Buffer
    CALL FUNCTION '/DMO/FLIGHT_TRAVEL_INITIALIZE'.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.

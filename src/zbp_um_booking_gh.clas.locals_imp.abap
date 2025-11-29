CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
* Table type definition
    TYPES : t_t_failed_booking   TYPE TABLE FOR FAILED zi_um_booking_gh_m,
            t_t_reported_booking TYPE TABLE FOR REPORTED zi_um_booking_gh_m.

* Method definition to Update the Booking Entity Instance
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Booking.

* Method definition to Delete the Booking Entity Instance
    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Booking.

* Method definition to Read the Booking Entity Instance
    METHODS read FOR READ
      IMPORTING keys FOR READ Booking RESULT result.

* Method definition to Read the Travel Entity Instance by association
    METHODS rba_Travel FOR READ
      IMPORTING keys_rba FOR READ Booking\_Travel FULL result_requested RESULT result LINK association_links.
    METHODS map_messages
      IMPORTING
                cid          TYPE abp_behv_cid   OPTIONAL
                travel_id    TYPE /dmo/travel_id OPTIONAL
                booking_id   TYPE /dmo/booking_id OPTIONAL
                messages     TYPE /dmo/t_message
      EXPORTING failed_added TYPE abap_boolean
      CHANGING
                failed       TYPE t_t_failed_booking
                reported     TYPE t_t_reported_booking.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD update.
    DATA : wel_booking  TYPE /dmo/booking,
           wel_bookingx TYPE /dmo/s_booking_inx,
           wtl_messages TYPE /dmo/t_message.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>).
      wel_booking = CORRESPONDING #( <fs_entity> MAPPING FROM ENTITY ).
      wel_bookingx-booking_id = <fs_entity>-BookingId.
      wel_bookingx-action_code = /dmo/if_flight_legacy=>action_code-update.
      wel_bookingx-_intx = CORRESPONDING #( <fs_entity> MAPPING FROM ENTITY ).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
        EXPORTING
          is_travel   = VALUE /dmo/s_travel_in( travel_id = <fs_entity>-TravelId )
          is_travelx  = VALUE /dmo/s_travel_inx( travel_id = <fs_entity>-TravelId )
          it_booking  = VALUE /dmo/t_booking_in( ( CORRESPONDING #( wel_booking ) ) )
          it_bookingx = VALUE /dmo/t_booking_inx( ( CORRESPONDING #( wel_bookingx ) ) )
        IMPORTING
*         es_travel   =
*         et_booking  =
*         et_booking_supplement  =
          et_messages = wtl_messages.

*  To map the messages
      map_messages( EXPORTING
                      cid = <fs_entity>-%cid_ref
                      travel_id = <fs_entity>-TravelId
                      booking_id = <fs_entity>-BookingId
                      messages = wtl_messages
                    CHANGING
                      failed = failed-booking
                      reported = reported-booking ).
    ENDLOOP.


  ENDMETHOD.

  METHOD delete.
    DATA: wtl_messages TYPE /dmo/t_message.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
        EXPORTING
          is_travel   = VALUE /dmo/s_travel_in( travel_id = <fs_key>-TravelId )
          is_travelx  = VALUE /dmo/s_travel_inx( travel_id = <fs_key>-TravelId )
          it_booking  = VALUE /dmo/t_booking( ( booking_id = <fs_key>-BookingId ) )
          it_bookingx = VALUE /dmo/t_booking_inx( ( booking_id = <fs_key>-BookingId
                                                    action_code = /dmo/if_flight_legacy=>action_code-delete ) )
        IMPORTING
          et_messages = wtl_messages.

*  To map the messages
      map_messages(
        EXPORTING
          cid          =    <fs_key>-%cid_ref
          travel_id    = <fs_key>-TravelId
          booking_id   = <fs_key>-BookingId
          messages     = wtl_messages
        IMPORTING
          failed_added = DATA(wl_failed_added)
        CHANGING
          failed       = failed-booking
          reported     = reported-booking
      ).

    ENDLOOP.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_Travel.
    DATA: wel_travel_out  TYPE /dmo/travel,
          wtl_booking_out TYPE /dmo/t_booking,
          wtl_messages    TYPE /dmo/t_message.
* This method will trigger either from external code or during update operation if dependent etag is used for lock
    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<fs_key_rba>) GROUP BY <fs_key_rba>-BookingId.
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <fs_key_rba>-TravelId
*         iv_include_buffer     = abap_true
        IMPORTING
          es_travel    = wel_travel_out
          et_booking   = wtl_booking_out
*         et_booking_supplement =
          et_messages  = wtl_messages.

* TO map the messages
      map_messages(
        EXPORTING
*          cid          =
          travel_id    = <fs_key_rba>-TravelId
          booking_id   = <fs_key_rba>-BookingId
          messages     = wtl_messages
        IMPORTING
          failed_added = DATA(wl_failed_added)
        CHANGING
          failed       = failed-booking
          reported     = reported-booking
      ).

      IF wl_failed_added EQ ABAP_false.
        LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<fs_key>) USING KEY entity WHERE TravelId = <fs_key_rba>-TravelId.
          INSERT INITIAL LINE INTO TABLE association_links ASSIGNING FIELD-SYMBOL(<fs_asso_link>).
          IF sy-subrc = 0 AND <fs_asso_link> IS ASSIGNED.
            <fs_asso_link>-source-%tky = <fs_key>-%tky.
            <fs_asso_link>-target-TravelId = <fs_key>-TravelId.
          ENDIF.

          IF result_requested = abap_true.
            APPEND CORRESPONDING #( wel_travel_out MAPPING TO ENTITY ) TO result.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    SORT association_links BY source ASCENDING.
    DELETE ADJACENT DUPLICATES FROM association_links COMPARING ALL FIELDS.

    SORT result BY %tky ASCENDING.
    DELETE ADJACENT DUPLICATES FROM result COMPARING ALL FIELDS.
  ENDMETHOD.


  METHOD map_messages.
    failed_added = abap_false.

    LOOP AT messages ASSIGNING FIELD-SYMBOL(<fs_messages>).
      IF <fs_messages>-msgty EQ 'E' OR <fs_messages>-msgty EQ 'A'.
        APPEND INITIAL LINE TO failed ASSIGNING FIELD-SYMBOL(<fs_failed>).
        IF <fs_failed> IS ASSIGNED.
          <fs_failed>-%cid = cid.
          <fs_failed>-TravelId = travel_id.
          <fs_failed>-BookingId = booking_id.
          <fs_failed>-%fail-cause = /dmo/cl_travel_auxiliary=>get_cause_from_message(
                                      msgid        = <fs_messages>-msgid
                                      msgno        = <fs_messages>-msgno
*                                  is_dependend = abap_false
                                    ).
          UNASSIGN <fs_failed>.
        ENDIF.

        APPEND INITIAL LINE TO reported ASSIGNING FIELD-SYMBOL(<fs_reported>).
        IF <fs_reported> IS ASSIGNED.
          <fs_reported>-%cid = cid.
          <fs_reported>-%msg = new_message(
                                 id       = <fs_messages>-msgid
                                 number   = <fs_messages>-msgno
                                 severity = if_abap_behv_message=>severity-error
                                 v1       = <fs_messages>-msgv1
                                 v2       = <fs_messages>-msgv2
                                 v3       = <fs_messages>-msgv3
                                 v4       = <fs_messages>-msgv4
                               ).
          <fs_reported>-TravelId = travel_id.
          <fs_reported>-BookingId = booking_id.
          UNASSIGN <fs_reported>.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

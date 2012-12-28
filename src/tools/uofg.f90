! THIS VERSION: CUTEST 1.0 - 23/12/2012 AT 16:10 GMT.

!-*-*-*-*-*-*-*-  C U T E S T    U O F G    S U B R O U T I N E  -*-*-*-*-*-*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   fortran 2003 version released in CUTEst, 23rd December 2012

      SUBROUTINE CUTEST_uofg( status, n, X, f, G, grad )
      USE CUTEST
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )

!  dummy arguments

      INTEGER, INTENT( IN ) :: n
      INTEGER, INTENT( OUT ) :: status
      REAL ( KIND = wp ), INTENT( OUT ) :: f
      LOGICAL, INTENT( IN ) :: grad
      REAL ( KIND = wp ), INTENT( IN ), DIMENSION( n ) :: X
      REAL ( KIND = wp ), INTENT( OUT ), DIMENSION( n ) :: G

!  ---------------------------------------------------------------
!  compute the value of the objective function and its gradient
!  for a function initially written in Standard Input Format (SIF)

!  G     is an array which gives the value of the gradient of the 
!        objective function evaluated at X. G(i) gives the partial 
!        derivative of the objective function wrt variable X(i)
!  ---------------------------------------------------------------

      CALL CUTEST_uofg_threadsafe( CUTEST_data_global,                         &
                                   CUTEST_work_global( 1 ),                    &
                                   status, n, X, f, G, grad )
      RETURN

!  end of subroutine CUTEST_uofg

      END SUBROUTINE CUTEST_uofg

!-*-*-   C U T E S T    U O F G _ t h r e a d e d   S U B R O U T I N E  -*-*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   fortran 2003 version released in CUTEst, 23rd December 2012

      SUBROUTINE CUTEST_uofg_threaded( status, n, X, f, G, grad, thread )
      USE CUTEST
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )

!  dummy arguments

      INTEGER, INTENT( IN ) :: n, thread
      INTEGER, INTENT( OUT ) :: status
      REAL ( KIND = wp ), INTENT( OUT ) :: f
      LOGICAL, INTENT( IN ) :: grad
      REAL ( KIND = wp ), INTENT( IN ), DIMENSION( n ) :: X
      REAL ( KIND = wp ), INTENT( OUT ), DIMENSION( n ) :: G

!  ---------------------------------------------------------------
!  compute the value of the objective function and its gradient
!  for a function initially written in Standard Input Format (SIF)

!  G     is an array which gives the value of the gradient of the 
!        objective function evaluated at X. G(i) gives the partial 
!        derivative of the objective function wrt variable X(i)
!  ---------------------------------------------------------------

      CALL CUTEST_uofg_threadsafe( CUTEST_data_global,                         &
                                   CUTEST_work_global( thread ),               &
                                   status, n, X, f, G, grad )
      RETURN

!  end of subroutine CUTEST_uofg_threaded

      END SUBROUTINE CUTEST_uofg_threaded

!-*-   C U T E S T    U O F G _ t h r e a d s a f e   S U B R O U T I N E   -*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal authors: Ingrid Bongartz and Nick Gould

!  History -
!   fortran 77 version originally released in CUTE, February 1993
!   fortran 2003 version released in CUTEst, 20th November 2012

      SUBROUTINE CUTEST_uofg_threadsafe( data, work, status, n, X, f, G, grad )
      USE CUTEST
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )

!  dummy arguments

      TYPE ( CUTEST_data_type ), INTENT( IN ) :: data
      TYPE ( CUTEST_work_type ), INTENT( INOUT ) :: work
      INTEGER, INTENT( IN ) :: n
      INTEGER, INTENT( OUT ) :: status
      REAL ( KIND = wp ), INTENT( OUT ) :: f
      LOGICAL, INTENT( IN ) :: grad
      REAL ( KIND = wp ), INTENT( IN ), DIMENSION( n ) :: X
      REAL ( KIND = wp ), INTENT( OUT ), DIMENSION( n ) :: G

!  ---------------------------------------------------------------
!  compute the value of the objective function and its gradient
!  for a function initially written in Standard Input Format (SIF)

!  G     is an array which gives the value of the gradient of the 
!        objective function evaluated at X. G(i) gives the partial 
!        derivative of the objective function wrt variable X(i)
!  ---------------------------------------------------------------

!  local variables

      INTEGER :: i, j, ig, ifstat, igstat
      REAL ( KIND = wp ) :: ftt
      EXTERNAL :: RANGE 

!  there are non-trivial group functions

      DO i = 1, MAX( data%nel, data%ng )
        work%ICALCF( i ) = i
      END DO

!  evaluate the element function values

      CALL ELFUN( work%FUVALS, X, data%EPVALU, data%nel, data%ITYPEE,          &
                  data%ISTAEV, data%IELVAR, data%INTVAR, data%ISTADH,          &
                  data%ISTEP, work%ICALCF, data%ltypee, data%lstaev,           &
                  data%lelvar, data%lntvar, data%lstadh, data%lstep,           &
                  data%lcalcf, data%lfuval, data%lvscal, data%lepvlu,          &
                  1, ifstat )
      IF ( ifstat /= 0 ) GO TO 930

!  compute the group argument values ft

      DO ig = 1, data%ng
        ftt = - data%B( ig )

!  include the contribution from the linear element only if the variable 
!  belongs to the first n variables

        DO i = data%ISTADA( ig ), data%ISTADA( ig + 1 ) - 1
          j = data%ICNA( i ) 
          IF ( j <= n ) ftt = ftt + data%A( i ) * X( j )
        END DO

!  include the contributions from the nonlinear elements

        DO i = data%ISTADG( ig ), data%ISTADG( ig + 1 ) - 1
          ftt = ftt + data%ESCALE( i ) * work%FUVALS( data%IELING( i ) )
        END DO
        work%FT( ig ) = ftt

!  record the derivatives of trivial groups

        IF ( data%GXEQX( ig ) ) work%GVALS( ig, 2 ) = 1.0_wp
      END DO

!  compute the group function values

!  all group functions are trivial

      IF ( data%altriv ) THEN
        f = DOT_PRODUCT( data%GSCALE( : data%ng ), work%FT( : data%ng ) )
        work%GVALS( : data%ng, 1 ) = work%FT( : data%ng )
        work%GVALS( : data%ng, 2 ) = 1.0_wp

!  evaluate the group function values

      ELSE
        CALL GROUP( work%GVALS, data%ng, work%FT, data%GPVALU, data%ng,        &
                    data%ITYPEG, data%ISTGP, work%ICALCF, data%ltypeg,         &
                    data%lstgp, data%lcalcf, data%lcalcg, data%lgpvlu,         &
                    .FALSE., igstat )
        IF ( igstat /= 0 ) GO TO 930

!  compute the objective function value

        f = 0.0_wp
        DO ig = 1, data%ng
          IF ( data%GXEQX( ig ) ) THEN
            f = f + data%GSCALE( ig ) * work%FT( ig )
          ELSE
            f = f + data%GSCALE( ig ) * work%GVALS( ig, 1 )
          END IF
        END DO
      END IF

!  evaluate the element function derivatives

      IF ( grad ) THEN
        CALL ELFUN( work%FUVALS, X, data%EPVALU, data%nel, data%ITYPEE,        &
                    data%ISTAEV, data%IELVAR, data%INTVAR, data%ISTADH,        &
                    data%ISTEP, work%ICALCF, data%ltypee, data%lstaev,         &
                    data%lelvar, data%lntvar, data%lstadh, data%lstep,         &
                    data%lcalcf, data%lfuval, data%lvscal, data%lepvlu,        &
                    2, ifstat )
        IF ( ifstat /= 0 ) GO TO 930

!  evaluate the group derivative values

        IF ( .NOT. data%altriv ) THEN
          CALL GROUP( work%GVALS, data%ng, work%FT, data%GPVALU, data%ng,      &
                      data%ITYPEG, data%ISTGP, work%ICALCF, data%ltypeg,       &
                      data%lstgp, data%lcalcf, data%lcalcg, data%lgpvlu,       &
                      .TRUE., igstat )
          IF ( igstat /= 0 ) GO TO 930
        END IF

!  compute the gradient values

      CALL CUTEST_form_gradients( n, data%ng, data%nel, data%ntotel,           &
             data%nvrels, data%nnza, data%nvargp, work%firstg, data%ICNA,      &
             data%ISTADA, data%IELING, data%ISTADG, data%ISTAEV,               &
             data%IELVAR, data%INTVAR, data%A, work%GVALS( : , 2 ),            &
             work%FUVALS, data%lnguvl, work%FUVALS( data%lggfx + 1 ),          &
             data%GSCALE, data%ESCALE, work%FUVALS( data%lgrjac + 1 ),         &
             data%GXEQX, data%INTREP, data%ISVGRP, data%ISTAGV, data%ITYPEE,   &
             work%ISTAJC, work%W_ws, work%W_el, RANGE )
        work%firstg = .FALSE.

!  store the gradient value

        DO i = 1, n
          G( i ) = work%FUVALS( data%lggfx + i )
        END DO
      END IF

!  update the counters for the report tool

      work%nc2of = work%nc2of + 1
      IF ( grad ) work%nc2og = work%nc2og + 1
      status = 0
      RETURN

!  unsuccessful returns

  930 CONTINUE
      IF ( data%out > 0 ) WRITE( data%out,                                     &
        "( ' ** SUBROUTINE UOFG: Error flag raised during SIF evaluation' )" )
      status = 3
      RETURN

!  end of subroutine CUTEST_uofg_threadsafe

      END SUBROUTINE CUTEST_uofg_threadsafe

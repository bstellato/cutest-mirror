C     ( Last modified on 12 Sep 2007 at 11:20:00 )
      PROGRAM          LBFGSB_main
C
C  LBFGSB test driver for problems derived from SIF files.
C
C  Nick Gould, for CGT Productions.
C  September 2004
C
      INTEGER          NMAX  , LH, I, IOUT, N , M , INPUT,
     *                 LP, MP, LW, J, MAXIT   , L , NA   , 
     *                 IFLAG , INSPEC, MMAX, IPRINT, LWA, LIWA
CS    REAL             F, EPS, GTOL  , GNORM , ZERO, ONE,
CD    DOUBLE PRECISION F, EPS, GTOL  , GNORM , ZERO, ONE,
     *                 PGTOL, FACTR, INFTY
      CHARACTER * 60   TASK, CSAVE
      LOGICAL          LSAVE( 4 )
CCUS  PARAMETER      ( NMAX = 100000, MMAX = 25 )
CBIG  PARAMETER      ( NMAX = 100000, MMAX = 25 )
CMED  PARAMETER      ( NMAX =  10000, MMAX = 25 )
CTOY  PARAMETER      ( NMAX =   1000, MMAX = 25 )
      PARAMETER      ( LIWA = 3 * NMAX )
      PARAMETER      ( LWA  = 2 * MMAX * NMAX + 4 * NMAX + 
     *                 12 * MMAX *MMAX + 12 * MMAX )
      PARAMETER      ( IOUT  = 6 )
      INTEGER          NBD( NMAX ), IWA( LIWA ), ISAVE( 44 )
CS    REAL             X( NMAX ), XL( NMAX ), XU( NMAX ), G( NMAX ), 
CD    DOUBLE PRECISION X( NMAX ), XL( NMAX ), XU( NMAX ), G( NMAX ), 
     +                 WA( LWA ), DSAVE( 29 )
      PARAMETER      ( INPUT = 55, INSPEC = 56 )
CS    PARAMETER      ( ZERO = 0.0E0, ONE = 1.0E0, INFTY = 1.0E+19 )
CD    PARAMETER      ( ZERO = 0.0D0, ONE = 1.0D0, INFTY = 1.0D+19 )
      CHARACTER * 10   XNAMES( NMAX ), PNAME, SPCDAT
      REAL             CPU( 2 ), CALLS( 4 )
      EXTERNAL         SETULB
C     
C  Open the Spec file for the method.
C
      SPCDAT = 'LBFGSB.SPC'
      OPEN ( INSPEC, FILE = SPCDAT, FORM = 'FORMATTED',
     *      STATUS = 'OLD' )
      REWIND INSPEC
C
C  Read input Spec data.
C
C     M        : the maximum number of variable metric corrections
C     MAXIT    : the maximum number of iterations,
C     IPRINT   : print level (<0,none,=0,one line/iteration,>1,more detail)
C     FACTR    : the function accuracy tolerence (see hint below)
C     PGTOL    : the required norm of the projected gradient
C
C  Hint - the iteration will stop when
C
C         (f^k - f^{k+1})/max{|f^k|,|f^{k+1}|,1} <= factr*epsmch
C
C   where epsmch is the machine precision, which is automatically
C   generated by the code. Typical values for factr: 1.d+12 for
C   low accuracy; 1.d+7 for moderate accuracy; 1.d+1 for extremely
C   high accuracy.

      READ ( INSPEC, 1000 ) M, MAXIT, IPRINT, FACTR, PGTOL
C
C  Close input file.
C
      CLOSE ( INSPEC )
C
C  Open the relevant file.
C
      OPEN ( INPUT, FILE = 'OUTSDIF.d', FORM = 'FORMATTED',
     *       STATUS = 'OLD' )
C
C  Check to see if there is sufficient room
C
      CALL UDIMEN( INPUT, N )
      IF ( N .GT. NMAX ) THEN
        WRITE( IOUT, 2040 ) 'X     ', 'NMAX  ', N
        STOP
      END IF
C
C  Set up SIF data.
C
      CALL USETUP( INPUT, IOUT, N, X, XL, XU, NMAX )
C
C  Set bound constraint status
C
      DO 10 I = 1, N
         IF( XL( I ) .LE. - INFTY ) THEN
            IF( XU( I ) .GE. INFTY ) THEN
               NBD( I ) = 0
            ELSE
               NBD( I ) = 3
            END IF
         ELSE
            IF( XU( I ) .GE. INFTY ) THEN
               NBD( I ) = 1
            ELSE
               NBD( I ) = 2
            END IF
         END IF
   10 CONTINUE
C
C  Obtain variable names.
C
      CALL UNAMES( N, PNAME, XNAMES )
C
C  Set up algorithmic input data.
C
      LP     = IOUT
      MP     = IOUT
      IFLAG  = 0
C
C  Optimization loo
C
      TASK = 'START'
   30 CONTINUE
C
C  Call the optimizer
C
         CALL SETULB( N, M, X, XL, XU, NBD, F, G, FACTR, PGTOL, WA, 
     +                IWA, TASK, IPRINT, CSAVE, LSAVE, ISAVE, DSAVE )
C
C  Evaluate the function, f, and gradient, G
C
         IF (TASK( 1: 2 ) .EQ. 'FG' ) THEN
            CALL UOFG( N, X, F, G, .TRUE. )
            GO TO 30
C
C  Test for convergence
C 
         ELSE IF ( TASK( 1: 4 ) .EQ. 'CONV' ) THEN
            IFLAG = 0
         ELSE IF (  TASK( 1: 4 ) .EQ. 'ABNO' ) THEN
            IFLAG = 1
            WRITE( IOUT, "( ' Abnormal exit ' )" )
         ELSE IF (  TASK( 1: 5 ) .EQ. 'ERROR' ) THEN
            IFLAG = 2
            WRITE( IOUT, "( ' Error exit ' )" )
         ELSE IF (  TASK( 1: 5 ) .EQ. 'NEW_X' ) THEN
            IF ( ISAVE( 30 ) .GT. MAXIT ) THEN
              IFLAG = 3
              WRITE( IOUT, 
     *           "( ' Maximum number of iterations exceeded ' )" )
            ELSE
               GO TO 30
            END IF
         END IF
C
C  Terminal exit.
C
      CALL UREPRT( CALLS, CPU )
      GNORM = DSAVE( 13 )
      WRITE ( IOUT, 2010 ) F, GNORM
      DO 120 I = 1, N
         WRITE( IOUT, 2020 ) XNAMES( I ), XL( I ), X( I ), XU( I ), 
     *                       G( I )
  120 CONTINUE
      WRITE ( IOUT, 2000 ) PNAME, N, INT( CALLS(1) ), INT( CALLS(2) ),
     *                     IFLAG, F, CPU(1), CPU(2) 
      CLOSE( INPUT  )
      STOP
C
C  Non-executable statements.
C
 1000 FORMAT( 3( I10, / ), ( D10.3, / ), D10.3 )
 2000 FORMAT( /, 24('*'), ' CUTEr statistics ', 24('*') //
     *    ,' Code used               :  L-BFGS-B',     /
     *    ,' Problem                 :  ', A10,    /
     *    ,' # variables             =      ', I10 /
     *    ,' # objective functions   =      ', I10 /
     *    ,' # objective gradients   =      ', I10 / 
     *     ' Exit code               =      ', I10 /
     *    ,' Final f                 = ', E15.7 /
     *    ,' Set up time             =      ', 0P, F10.2, ' seconds' /
     *     ' Solve time              =      ', 0P, F10.2, ' seconds' //
     *     66('*') / )
 2010 FORMAT( ' Final objective function value   = ', 1P, D12.4, 
     *        /, ' Final norm of projected gradient = ', 1P, D12.4,
     *        //, '                XL           X        XU', 
     *           '           G ' )
 2020 FORMAT(  1X, A10, 1P, 4D12.4 )
 2040 FORMAT( /, ' ** ERROR from LBBMA. The declared array ', A6, 
     *           ' is too small to hold the problem data.', /, 
     *           ' Increase ', A6, ' in LBBMA to be at least ', I6, 
     *           ' and recompile. Stopping ' )
      END

      SUBROUTINE REORDA( NC, NNZ, IRN, JCN, A, IP, IW )
      INTEGER NC, NNZ
      INTEGER IRN( NNZ  ), JCN( NNZ )
      INTEGER IW( NC + 1 ), IP( NC + 1 )
CS    REAL              A( NNZ )
CD    DOUBLE PRECISION  A( NNZ )

C  Sort a sparse matrix from arbitrary order to column order

C  Nick Gould
C  7th November, 1990

      INTEGER I, J, K, L, IC, NCP1, ITEMP, JTEMP,  LOCAT
CS    REAL             ANEXT , ATEMP
CD    DOUBLE PRECISION ANEXT , ATEMP

C  Initialize the workspace as zero

      NCP1       = NC + 1
      DO 10 J    = 1, NCP1
         IW( J ) = 0
   10 CONTINUE

C  Pass 1. Count the number of elements in each column

      DO 20 K   = 1, NNZ
        J       = JCN( K )
        IW( J ) = IW( J ) + 1
   20 CONTINUE

C  Put the positions where each column begins in
C  a compressed collection into IP and IW

      IP( 1 )       = 1
      DO 30 J       = 2, NCP1
        IP( J )     = IW( J - 1 ) + IP( J - 1 )
        IW( J - 1 ) = IP( J - 1 )
   30 CONTINUE

C  Pass 2. Reorder the elements into column order. 
C          Fill in each column in turn

      DO 70 IC = 1, NC

C  Consider the next unfilled position in column IC

        DO 60 K = IW( IC ), IP( IC + 1 ) - 1

C  The entry should be placed in column J

          I       = IRN( K )
          J       = JCN( K )
          ANEXT   = A( K )
          DO 40 L = 1, NNZ

C  See if the entry is already in place

             IF ( J .EQ. IC ) GO TO 50
             LOCAT = IW( J )

C  As a new entry is placed in column J, increase the pointer 
C  IW( J ) by one

             IW( J  ) = LOCAT + 1

C  Record details of the entry which currently occupies location LOCAT

             ITEMP = IRN( LOCAT )
             JTEMP = JCN( LOCAT )
             ATEMP = A( LOCAT )

C  Move the new entry to its correct place

             IRN( LOCAT ) = I 
             JCN( LOCAT ) = J  
             A( LOCAT )   = ANEXT

C  Make the displaced entry the new entry

             I          = ITEMP
             J          = JTEMP
             ANEXT      = ATEMP
   40     CONTINUE

C  Move the new entry to its correct place 

   50     CONTINUE
          JCN( K ) = J
          IRN( K ) = I
          A( K )   = ANEXT
   60   CONTINUE
   70 CONTINUE

      RETURN

C  End of REORDA

      END

      SUBROUTINE TIMER( TTIME )

C  CPU timer

CS    REAL             TTIME
CD    DOUBLE PRECISION TTIME
      REAL             CPUTIM, DUM
      EXTERNAL         CPUTIM

      TTIME = CPUTIM( DUM )

      RETURN
      END LBFGSB_main

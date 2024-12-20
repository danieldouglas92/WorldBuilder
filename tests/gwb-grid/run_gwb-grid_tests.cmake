# arguments checking
if( NOT DEFINED TEST_NAME )
  message( FATAL_ERROR "Require TEST_NAME to be defined." )
endif( NOT DEFINED TEST_NAME )
if( NOT DEFINED TEST_PROGRAM )
  message( FATAL_ERROR "Require TEST_PROGRAM to be defined." )
endif( NOT DEFINED TEST_PROGRAM )
if( NOT DEFINED TEST_OUTPUT )
  message( FATAL_ERROR "Require TEST_OUTPUT to be defined" )
endif( NOT DEFINED TEST_OUTPUT )
if( NOT DEFINED TEST_REFERENCE )
  message( FATAL_ERROR "Require TEST_REFERENCE to be defined" )
endif( NOT DEFINED TEST_REFERENCE )
if( NOT DEFINED REPLACE_FAILING_TEST_RESULTS )
  message( FATAL_ERROR "Require REPLACE_FAILING_TEST_RESULTS to be defined" )
endif( NOT DEFINED REPLACE_FAILING_TEST_RESULTS )

# create a directory for the test
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/gwb-grid/${TEST_NAME})

set(EXECUTE_COMMAND ${TEST_PROGRAM} ${TEST_ARGS})

# run the test program, capture the stdout/stderr and the result var ${TEST_ARGS}
execute_process(
  COMMAND ${TEST_PROGRAM} ${TEST_ARGS} 
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/gwb-grid/ 
  OUTPUT_FILE ${TEST_OUTPUT}.log
  ERROR_VARIABLE TEST_ERROR_VAR
  RESULT_VARIABLE TEST_RESULT_VAR
  OUTPUT_VARIABLE TEST_OUTPUT_VAR
  )

# if the return value is !=0 bail out
if( TEST_RESULT_VAR )
	message( FATAL_ERROR "Failed: Test program ${TEST_PROGRAM} exited != 0.\n${TEST_ERROR_VAR}" )
endif( TEST_RESULT_VAR )
file(TO_NATIVE_PATH "${TEST_OUTPUT}" TEST_NATIVE_OUTPUT)
file(TO_NATIVE_PATH "${TEST_REFERENCE}" TEST_NATIVE_REFERENCE)

FIND_PROGRAM(DIFF_EXECUTABLE
	     NAMES diff FC
	     HINTS ${DIFF_DIR}
	     PATH_SUFFIXES bin
	     )

 IF(NOT DIFF_EXECUTABLE MATCHES "-NOTFOUND")
	 SET(TEST_DIFF ${DIFF_EXECUTABLE})
 ELSE()
	     MESSAGE(FATAL_ERROR
		     "Could not find diff or fc. This is required for running the testsuite.\n"
		     "Please specify TEST_DIFF by hand."
		     )
ENDIF()

IF("${TEST_DIFF}" MATCHES ".*exe")
  # windows
  FIND_PROGRAM(DOS2UNIX_EXECUTABLE
	     NAMES dos2unix
	     HINTS ${DIFF_DIR}
	     PATH_SUFFIXES bin
	     )
     IF(NOT DOS2UNIX_EXECUTABLE MATCHES "-NOTFOUND")
	     SET(TEST_D2U ${DOS2UNIX_EXECUTABLE})
     ELSE()
	     MESSAGE(FATAL_ERROR
		     "Could not find dos2unix. This is required for running the testsuite in windows.\n"
		     "Please specify TEST_D2U by hand."
		     )
     ENDIF()
     execute_process(COMMAND ${TEST_D2U} ${TEST_NATIVE_OUTPUT})
     execute_process(COMMAND ${TEST_D2U} ${TEST_NATIVE_REFERENCE})
ENDIF()

# now compare the output with the reference
execute_process(
	COMMAND ${TEST_DIFF} -q  ${TEST_NATIVE_OUTPUT} ${TEST_NATIVE_REFERENCE}
  RESULT_VARIABLE TEST_RESULT
  )

# again, if return value is !=0 scream and shout
if( TEST_RESULT )
  if( REPLACE_FAILING_TEST_RESULTS )
	  file(COPY_FILE ${TEST_NATIVE_OUTPUT} ${TEST_NATIVE_REFERENCE} )
  endif( REPLACE_FAILING_TEST_RESULTS )
	execute_process(COMMAND ${TEST_DIFF} ${TEST_NATIVE_OUTPUT} ${TEST_NATIVE_REFERENCE})
	message( FATAL_ERROR "Failed: The output of ${TEST_NAME} stored in ${TEST_NATIVE_OUTPUT} did not match the reference output stored in ${TEST_NATIVE_REFERENCE}")
endif( TEST_RESULT )

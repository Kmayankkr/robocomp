
MACRO( ROBOCOMP_INITIALIZE )
  set(RoboComp_VERSION 1.0 CACHE STRING "RoboComp version")
  #set install dirs
  set(BIN_INSTALL_DIR "/opt/robocomp-${RoboComp_VERSION}/bin")
  set(CONFIG_INSTALL_DIR "/opt/robocomp-${RoboComp_VERSION}/etc-default")
  # Set root directory
  SET( ROBOCOMP_ROOT ${ARGN} )
  MESSAGE(STATUS "RoboComp root is now set to ${ROBOCOMP_ROOT}")
  # Include path directories
  INCLUDE_DIRECTORIES (
    .
    ${ARGN}/classes/
    ${ARGN}/libs/
    ${ARGN}/interfaces/
    ${CMAKE_BINARY_DIR}
    ${ICEROOT}/include/
  )
  # Set interfaces directory
  SET(RoboComp_INTERFACES_DIR "${ARGN}/interfaces/")

  MESSAGE(STATUS ${OSGUTIL_LIBRARY})

  FIND_PACKAGE( Threads)
  FIND_PACKAGE( Ice REQUIRED COMPONENTS Ice IceStorm OPTIONAL_COMPONENTS IceUtil )
 
  SET( LIBS ${LIBS} -L/opt/robocomp/lib ${OSG_LIBRARY} -losgViewer -losg -losgUtil  -losgGA ${OSGDB_LIBRARY} ${OSGVIEWER_LIBRARY} ${OPENTHREADS_LIBRARY}  -L${ROBOCOMP_ROOT}/classes ${CMAKE_THREAD_LIBS_INIT} -lboost_system  robocomp_qmat ${IPP_LIBS} robocomp_innermodel robocomp_osgviewer)
 
ENDMACRO( ROBOCOMP_INITIALIZE )


MACRO( ROBOCOMP_LIBRARY )
  MESSAGE(STATUS "RoboComp libraries")
  FOREACH ( input_library ${ARGN} )
	IF( EXISTS "/opt/robocomp/lib/librobocomp_${input_library}.so")
		MESSAGE(STATUS "Adding library robocomp_${input_library} " )
		SET(ROBOCOMP_LIBS ${ROBOCOMP_LIBS} -lrobocomp_${input_library} )
	ELSE( EXISTS "/opt/robocomp/lib/librobocomp_${input_library}.so")
		MESSAGE(STATUS "Library ${input_library} not found in /opt/robocomp/lib" )
	ENDIF( EXISTS "/opt/robocomp/lib/librobocomp_${input_library}.so")
  ENDFOREACH ( input_library )
  SET( LIBS ${LIBS} -L/opt/robocomp/lib/ ${ROBOCOMP_LIBS} )
ENDMACRO( ROBOCOMP_LIBRARY )



MACRO( ROBOCOMP_WRAP_ICE )
  # External Slice source paths
  SET (EXTERNAL_SLICE "")
  SET (SLICE_PATH "$ENV{SLICE_PATH};")
  SET (INC_ROBOCOMPSLICE_PATH "true" )
  SET (ADDITIONAL_SLICE_INCLUDE_PATH "")
  FOREACH (SPATH ${SLICE_PATH})
     #MESSAGE(STATUS "ACHO ${SLICE_PATH}")
     IF( ${RoboComp_INTERFACES_DIR} STREQUAL ${SPATH})
       SET(INC_ROBOCOMPSLICE_PATH "false")
     ELSE( ${RoboComp_INTERFACES_DIR} STREQUAL ${SPATH})
			SET(ADDITIONAL_SLICE_INCLUDE_PATH ${ADDITIONAL_SLICE_INCLUDE_PATH} -I${SPATH})
     ENDIF( ${RoboComp_INTERFACES_DIR} STREQUAL ${SPATH})
  ENDFOREACH (SPATH ${SLICE_PATH})
  IF (${INC_ROBOCOMPSLICE_PATH} STREQUAL "true")
     SET (SLICE_PATH "${SLICE_PATH};${RoboComp_INTERFACES_DIR}")
  ENDIF(${INC_ROBOCOMPSLICE_PATH} STREQUAL "true")
  MESSAGE(STATUS "$SLICE_PATH=\"${SLICE_PATH}\"")
  FOREACH (SPATH ${SLICE_PATH})
    MESSAGE(STATUS "Adding ${SPATH} to the Slice directory set.")
    SET (EXTERNAL_SLICE "${EXTERNAL_SLICE} -I${SPATH} ")
  ENDFOREACH (SPATH)

  FOREACH( input_file ${ARGN} )
    SET (SLICE_FILE_FOUND "false")
	IF( input_file STREQUAL "Logger" )
		MESSAGE(STATUS "Compile with LoggerComp support." )
		ADD_DEFINITIONS(-DCOMPILE_LOGGERCOMP=1)
	ENDIF( input_file STREQUAL "Logger" )
    FOREACH (SPATH ${SLICE_PATH})
      IF (EXISTS "${SPATH}/${input_file}.ice")
        MESSAGE(STATUS "Adding rule to generate ${input_file}.cpp and ${input_file}.h from ${SPATH}/${input_file}.ice  (${SLICECPP_PATH}slice2cpp)" )
        ADD_CUSTOM_COMMAND (
          OUTPUT ${input_file}.cpp ${input_file}.h
          COMMAND ${SLICECPP_PATH}slice2cpp -I${RoboComp_INTERFACES_DIR} ${ADDITIONAL_SLICE_INCLUDE_PATH} -I. ${SPATH}/${input_file}.ice --output-dir .
          DEPENDS ${SPATH}/${input_file}.ice
          COMMENT "Generating ${input_file}.cpp and ${input_file}.h from ${input_file}.ice"
        )
        SET ( SOURCES ${SOURCES} ./${input_file}.cpp)
	    SET_PROPERTY(SOURCE ${input_file}.cpp PROPERTY SKIP_AUTOGEN ON)
        SET ( SLICE_FILE_FOUND "true")
	break ()
      ENDIF (EXISTS "${SPATH}/${input_file}.ice")
    ENDFOREACH (SPATH)
    IF (${SLICE_FILE_FOUND} STREQUAL "false")
      MESSAGE(FATAL_ERROR "${input_file}.ice not found in any of the Slice directories (${SLICE_PATH}).")
    ENDIF (${SLICE_FILE_FOUND} STREQUAL "false")
  ENDFOREACH( input_file )
ENDMACRO( ROBOCOMP_WRAP_ICE )


MACRO( ROBOCOMP_IDSL_TO_ICE )
  STRING (REPLACE "/" "_" SPECIFIC_TARGET "${CMAKE_CURRENT_SOURCE_DIR}") 
  ADD_CUSTOM_TARGET(ICES_${SPECIFIC_TARGET} ALL)
  SET( SPATH ${RoboComp_INTERFACES_DIR}/IDSLs/)
  FOREACH( input_file ${ARGN} )
      IF (EXISTS "${SPATH}/${input_file}.idsl")
        MESSAGE(STATUS "Adding rule to generate ${CMAKE_HOME_DIRECTORY}/interfaces/${input_file}.ice from ${SPATH}/${input_file}.idsl")
        add_custom_command(
          COMMAND "${ROBOCOMP_ROOT}/tools/robocompdsl/robocompdsl.py" ${SPATH}/${input_file}.idsl ${CMAKE_HOME_DIRECTORY}/interfaces/${input_file}.ice
          DEPENDS ${SPATH}/${input_file}.idsl
          COMMENT "Generating ${CMAKE_HOME_DIRECTORY}/interfaces/${input_file}.ice from ${SPATH}/${input_file}.idsl"
          TARGET ICES_${SPECIFIC_TARGET}
        )
      ELSE (EXISTS "${SPATH}/${input_file}.idsl")
        MESSAGE(FATAL_ERROR "${input_file}.idsl not found in (${SPATH}).")
      ENDIF (EXISTS "${SPATH}/${input_file}.idsl")
  ENDFOREACH( input_file )
ENDMACRO( ROBOCOMP_IDSL_TO_ICE )

MACRO( ROBOCOMP_ICE_TO_SRC )
  SET (SLICE_PATH "./src/;")
  STRING (REPLACE "/" "_" SPECIFIC_TARGET "${CMAKE_CURRENT_SOURCE_DIR}") 
  FOREACH( input_file ${ARGN} )
    MESSAGE(STATUS "Adding rule to generate ${input_file}.h and ${input_file}.cpp from ${CMAKE_HOME_DIRECTORY}/interfaces/${input_file}.ice")
    add_custom_command(
        OUTPUT ${input_file}.cpp ${input_file}.h
        COMMAND slice2cpp ${CMAKE_HOME_DIRECTORY}/interfaces/${input_file}.ice -I${CMAKE_HOME_DIRECTORY}/interfaces/ --output-dir .
        DEPENDS ICES_${SPECIFIC_TARGET}
        COMMENT "Generating ${input_file}.h and ${input_file}.cpp from ${CMAKE_HOME_DIRECTORY}/interfaces/${input_file}.ice"
    )
    SET ( SOURCES ${SOURCES} ./${input_file}.cpp )
    SET_PROPERTY(SOURCE ${input_file}.cpp PROPERTY SKIP_AUTOGEN ON)
  ENDFOREACH( input_file )
ENDMACRO( ROBOCOMP_ICE_TO_SRC )

INCLUDE_DIRECTORIES (
  ${CMAKE_CURRENT_BINARY_DIR}
  .
  ${ROBOCOMP_ROOT}/classes/
  ${CMAKE_BINARY_DIR}
)


MACRO( ROBOCOMP_WRAP_PYTHON_UI )
  FOREACH( input_file ${ARGN} )
    MESSAGE(STATUS "Adding rule to generate ui_${input_file}.py from ${input_file}.ui" )
    ADD_CUSTOM_COMMAND (
      OUTPUT ui_${input_file}.py
      COMMAND pysice-uic ${input_file}.ui -o ui_${input_file}.py
      DEPENDS ${input_file}.ui
      COMMENT "Generating ui_${input_file}.py from ${input_file}.ui"
    )
  ENDFOREACH( input_file )
ENDMACRO( ROBOCOMP_WRAP_PYTHON_UI )

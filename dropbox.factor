! Copyright (C) 2011 PolyMicro Systems.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators io io.directories io.files io.files.info
io.files.links io.files.private io.files.types io.pathnames kernel
locals sequences tools.continuations folder ;

IN: dropbox

TUPLE: dropbox ;

CONSTANT: db-library-folder " ~/Dropbox/Private/Library"
CONSTANT: user-library-folder " ~/Library"
CONSTANT: appsupport-name  "Application\ Support"
CONSTANT: preferences-name "Preferences"

:: is-linked-to-db? ( symlink -- ? )
    "Dropbox" symlink read-link start
    [ " to Dropbox" print f ]
    [ " not Dropbox" print t ] if
    ;

:: check-symbolic? ( path -- ? )
    path link-info type>> +symbolic-link+ =
    [ ", is symbolic" write  path is-linked-to-db? ]
    [ " , moving aside" print t ] if
    ;

:: moved-path? ( path -- ? )
    path write
    path exists?
    [ " path exists" write path check-symbolic? ]
    [ " no path, link it" print t ] if
    ;

: user-library-path ( -- path )
    user-library-folder as-directory
    ;

FROM: folder => with-directory-entries  ;
: do-appsupport ( -- )
    db-library-folder as-directory appsupport-name append
    [
        ! don't process hidden files like .DS_Store, only folders
        [ is-hidden? not ] filter
        ! switch to ~/L/AS
        user-library-path as-directory appsupport-name append
        absolute-path cd
        ! build seq of folders in ~/L/AS to be processed
        [ name>> cwd "/" append prepend ] map
        ! filter out all that already point to dropbox
        [ moved-path? ] filter
        ! This is the seq to be linked to Library
        [ link-to-current-directory ] each
    ] with-directory-entries
    ;

FROM: folder => with-directory-entries ;
: do-preferences ( -- )
    db-library-folder as-directory preferences-name append
    [
        ! don't process hidden files like .DS_Store, only folders
        [ is-hidden? not ] filter
        ! switch to ~/L/P
        user-library-path as-directory preferences-name append
        absolute-path cd
        ! build seq of folders in ~/P to be processed
        [ name>> cwd "/" append prepend ] map
        ! filter out all that already point to dropbox
        [ moved-path? ] filter
        ! This is the seq to be linked to Library
        [ link-to-current-directory ] each
    ] with-directory-entries
 ;

:: do-link ( folder -- )
    user-library-path absolute-path as-directory
    [ set-current-directory ] keep
    folder append 
    moved-path?
    [
        db-library-folder as-directory folder append
        link-to-current-directory
    ]
    [ ] if
;

: process-folder ( name -- )
    {
        { [ dup appsupport-name = ] [ drop do-appsupport ] }
        { [ dup preferences-name = ] [ drop do-preferences ] }
        [ do-link ]
    } cond
    ;

: library-items ( directory-files -- )
    [ dup type>> +directory+ =
      [ name>> process-folder ]
      [ drop ]
      if
    ] each
    ;

FROM: folder => with-directory-entries ;
: dbmain ( -- )
    db-library-folder exists?
    [
        db-library-folder absolute-path
        [ library-items ] with-directory-entries
    ] [
        "The folder " db-library-folder append
        " does not exist and it must to continue." append print
        " Check configuration setting in the \"dropbox\" vocabulary" print
    ] if
    ;

MAIN: dbmain
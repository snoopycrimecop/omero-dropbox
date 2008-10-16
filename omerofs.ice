/*
 *   $Id$
 * 
 *
 */

#ifndef OMERO_FS
#define OMERO_FS

#include <Ice/BuiltinSequences.ice>

module monitors {
    
    /*
     *      ==========================
     *      MonitorServer Declarations
     *      ==========================
     */
     
    /*
     *   Forward declarations
     *   ====================
     */
    interface MonitorClient;


    /*
     *   Exception declarations
     *   ======================
     */

    /*
     * OmeroFSError
     *
     * Just one catch-all UserException for the present. It could be 
     * subclassed to provide a finer grained level if necessary.
     */
    exception OmeroFSError {
        string reason;
    };


    /*
     *   Data declarations
     *   =================
     */
     
    /*
     * Enumeration for Monitor file types.
     * 
     */
    enum FileType { File, Dir, Link, Mount, Unknown };

    /*
     * File stats.
     *
     * What stats are likely to be needed? Could this struct be trimmed down
     * or does it need any further attributes?
     */
    struct FileStats {
        string baseName;
        string owner;
        long size;
        float mTime;
        float cTime;
        float aTime;
        FileType type;
    };
        
    /*
     * Enumeration for Monitor path modes.
     *
     * Flat, monitor the specified directory but not its subdirectories.
     * Recursive, monitor the specified directory and its subdirectories.
     * Follow,  monitor as Recursive but with new directories being added
     * to the monitor if they are created. 
     *
     * Not all path modes may be implemented for a given operating system.
     */
    enum PathMode { Flat, Recurse, Follow };
    
    /*
     * Enumeration for Monitor event types.
     * 
     * Create, notify on file creation only.
     * Modify, notify on file modification only.
     * Delete, notify on file deletion only.     
     * All, notify on all vents in the enumeration that apply to a given OS.     
     * 
     * Not all event types may be implemented for a given operating system.
     */
    enum EventType { Create, Modify, Delete, All };

    /*
     * Enumeration for Monitor state.
     * 
     * Stopped, a monitor exists but is not actively monitoring.
     * Started, a monitor exists and is actively monitoring.
     *
     */
    enum MonitorState { Stopped, Started };

    
    /*
     *   Interface declaration
     *   =====================
     */
    
    interface MonitorServer {
    
        /*
         * Monitor creation and control methods
         * ------------------------------------
         */
         
        /*
         * Create a monitor of events.
         * 
         * A exception will be raised if the event type or path mode is not supported by
         * the Monitor implementation for a given OS. An exception will be raised if the 
         * path does not exist or is inaccessible to the monitor. An exception will be raised
         * if a monitor cannot be created for any other reason.
         *
         * @param type, event type to monitor (EventType).
         * @param pathString, full path of directory of interest (string).
         * @param wl, list of extensions of interest (Ice::StringSeq).
         * @param mode, path mode of monitor (PathMode).
         * @param proxy, a proxy of the client to which notifications will be sent (MonitorClient*).
         * @return monitorId, a uuid1 (string).
         * @throws OmeroFSError
         */
        string createMonitor(EventType eType, string pathString, Ice::StringSeq whitelist, 
                                Ice::StringSeq blacklist, PathMode pMode, MonitorClient* proxy)
            throws OmeroFSError;
        
        /*
         * Start an existing monitor. 
         *
         * An exception will be raised if the id does not correspond to an existing monitor.
         * An exception will be raised if a monitor cannot be started for any other reason,
         * in this case the monitor's state cannot be assumed.
         *
         * @param id, monitor id (string).
         * @return, no explicit return value. 
         * @throws OmeroFSError
         */
        idempotent void startMonitor(string id)
            throws OmeroFSError;
            
        /*
         * Stop an existing monitor. 
         *
         * Attempting to stop a monitor that is not running raises no exception.
         * An exception will be raised if the id does not correspond to an existing monitor.
         * An exception will be raised if a monitor cannot be stopped for any other reason,
         * in this case the monitor's state cannot be assumed.
         *
         * @param id, monitor id (string).
         * @return, no explicit return value. 
         * @throws OmeroFSError
         */
        idempotent void stopMonitor(string id)
            throws OmeroFSError;
            
        /*
         * Destroy an existing monitor. 
         *
         * Attempting to destroy a monitor that is running will try to first stop
         * the monitor and then destroy it.
         * An exception will be raised if the id does not correspond to an existing monitor.
         * An exception will be raised if a monitor cannot be destroyed (or stopped and destroyed) 
         * for any other reason, in this case the monitor's state cannot be assumed.
         *
         * @param id, monitor id (string).
         * @return, no explicit return value. 
         * @throws OmeroFSError
         */
        idempotent void destroyMonitor(string id)
            throws OmeroFSError;


        /*
         * Get the state of an existing monitor. 
         *
         * An exception will be raised if the id does not correspond to an existing monitor.
         *
         * @param id, monitor id (string).
         * @return, the monitor state (MonitorState). 
         * @throws OmeroFSError
         */
        idempotent MonitorState getMonitorState(string id)
            throws OmeroFSError;


        /* 
         * Directory level methods
         * -----------------------
         */
        
        /*
         * Get the directory relative to an existing monitor on an OMERO.fs server.
         *
         * An exception will be raised if the id does not correspond to an existing monitor.
         * An exception will be raised if the path does not exist or is inaccessible to the 
         * OMERO.fs server. An exception will be raised if directory list cannot be 
         * returned for any other reason.
         *
         * @param id, monitor id (string).
         * @param relPath, the relative path from the monitor's watch path (string).
         * @param filter, a filter to apply to the listing, cf. ls (string).
         * @return, a directory listing (Ice::StringSeq). 
         * @throws OmeroFSError
         */
        idempotent Ice::StringSeq getMonitorDirectory(string id, string relPath, string filter)
            throws OmeroFSError;
            
        /*
         * Get an absolute directory from an OMERO.fs server.
         *
         * An exception will be raised if the path does not exist or is inaccessible to the 
         * OMERO.fs server. An exception will be raised if directory list cannot be 
         * returned for any other reason.
         *
         * @param relPath, an absolute path on the monitor's watch path (string).
         * @param filter, a filter to apply to the listing, cf. ls (string).
         * @return, a directory listing (Ice::StringSeq). 
         * @throws OmeroFSError
         */
        idempotent Ice::StringSeq getDirectory(string absPath, string filter)
            throws OmeroFSError;
        
        /* 
         * File level methods 
         * ------------------
         *
         *   fileId is used for file level operations, fileId is of the form:
         *
         *       omero-fs://url/path/to/file.ext
         */
         
        /*
         * Get base name of a file, this is the name 
         * stripped of any path, e.g. file.ext 
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return base name.
         * @throws OmeroFSError
         */
        idempotent string getBaseName(string fileId)
            throws OmeroFSError;
            
        /*
         * Get all FileStats of a file 
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return file stats (FileStats).
         * @throws OmeroFSError
         */
        idempotent FileStats getStats(string fileId)       
            throws OmeroFSError;
            
        /*
         * Get size of a file in bytes
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return byte size of file (long).
         * @throws OmeroFSError
         */
        idempotent long getSize(string fileId)
            throws OmeroFSError;
            
        /*
         * Get owner of a file
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return owner of file (string).
         * @throws OmeroFSError
         */
        idempotent string getOwner(string fileId)
            throws OmeroFSError;
            
        /*
         * Get ctime of a file
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return ctime of file (float).
         * @throws OmeroFSError
         */
        idempotent float getCTime(string fileId)
            throws OmeroFSError;
            
        /*
         * Get mtime of a file
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return mtime of file (float).
         * @throws OmeroFSError
         */
        idempotent float getMTime(string fileId)
            throws OmeroFSError;
            
        /*
         * Get atime of a file
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return atime of file (float).
         * @throws OmeroFSError
         */
        idempotent float getATime(string fileId)
            throws OmeroFSError;
            
        /*
         * Query whether file is a directory
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return true is directory (bool).
         * @throws OmeroFSError
         */
        idempotent bool isDir(string fileId)
            throws OmeroFSError;
            
        /*
         * Query whether file is a file 
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         *
         * @param fileId, see above.
         * @return true if file (bool).
         * @throws OmeroFSError
         */
        idempotent bool isFile(string fileId)
            throws OmeroFSError;
            
        /*
         * Get SHA1 of a file
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         * An exception will be raised if the SHA1 cannot be generated for any reason.
         *
         * @param fileId, see above.
         * @return SHA1 hex hash digest of file (string).
         * @throws OmeroFSError
         */
        idempotent string getSHA1(string fileId)
            throws OmeroFSError;
                    
        // 
        /*
         * readBlock should open, read size bytes from offset 
         * and then close the file. 
         *
         * An exception will be raised if the file no longer exists or is inaccessible.
         * An exception will be raised if the file read fails for any other reason.
         *
         * @param fileId, see above.
         * @param offset, byte offset into file from where read should begin (long).
         * @param size, number of bytes that should be read (int).
         * @return byte sequence of upto size bytes.
         * @throws OmeroFSError
         */
        idempotent Ice::ByteSeq readBlock(string fileId, long offset, int size)
            throws OmeroFSError;
        
    }; // end interface MonitorServer


    /*
     *  ==========================
     *  MonitorClient Declarations
     *  ==========================
     */
     
    /*
     *   Data declarations
     *   =================
     */

    /*
     * The id and type of an event. The file's basename is included for convenience,
     * other stats are not included since they may be unavailable for some event types.
     */
    struct EventInfo {
        string fileId;
        EventType type;
    };
        
    sequence<EventInfo> EventList;
    
    
    /*
     *  Interface declaration
     *  =====================
     * 
     *  This interface must be implemented by a client that
     *  wishes to subscribe to an OMERO.fs server.
     */
    interface  MonitorClient {
    
        /*
         * Callback, called by the monitor upon the proxy of the OMERO.fs client.
         *
         * @param id, monitor Id from which the event was reported (string).
         * @param el, list of events (EventList).
         * @return, no explicit return value.
         */
        void fsEventHappened(string id, EventList el);
    
    }; // end interface MonitorClient
    
}; // end module monitors

#endif
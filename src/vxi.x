/* Types */
typedef int Device_Link;
enum Device_AddrFamily {     /* used by interrupts */
    DEVICE_TCP = 0,
    DEVICE_UDP = 1
};
typedef int Device_Flags;
/*  Error types  */
typedef int Device_ErrorCode;
struct Device_Error {
    Device_ErrorCode   error;
};

struct Create_LinkParms {
    int          clientId;     /* implementation specific value */
    bool          lockDevice;   /* attempt to lock the device */
    unsigned int lock_timeout; /* time to wait on a lock */
    string        device<>;     /* name of device */
};
struct Create_LinkResp {
    Device_ErrorCode  error;
    Device_Link       lid;
    unsigned int     abortPort;   /* for the abort RPC */
    unsigned int     maxRecvSize; /* specifies max data size in bytes
                                      device will accept on a write */
};
struct Device_WriteParms {
    Device_Link       lid;          /* link id from create_link */
    unsigned int     io_timeout;   /* time to wait for I/O */
    unsigned int     lock_timeout; /* time to wait for lock */
    Device_Flags      flags;
    opaque            data<>;  /* the data length and the data itself */
};
struct Device_WriteResp  {
    Device_ErrorCode  error;
    unsigned int     size;    /* Number of bytes written */
};
struct Device_ReadParms {
    Device_Link      lid;          /* link id from create_link */
    unsigned int    requestSize;  /* Bytes requested */
    unsigned int    io_timeout;   /* time to wait for I/O */
    unsigned int    lock_timeout; /* time to wait for lock */
    Device_Flags     flags;
    int              termChar;     /* valid if flags & termchrset */
};
struct Device_ReadResp {
    Device_ErrorCode  error;
    int              reason;  /* Reason(s) read completed */
    opaque            data<>;  /* data.len and data.val */
};
struct Device_ReadStbResp {
    Device_ErrorCode  error;   /* error code */
    unsigned int      stb;     /* the returned status byte */
};
struct Device_GenericParms {
    Device_Link     lid;          /* Device_Link id from connect call */
    Device_Flags    flags;        /* flags with options */
    unsigned int   lock_timeout; /* time to wait for lock */
    unsigned int   io_timeout;   /* time to wait for I/O */
};
struct Device_RemoteFunc {
    unsigned int    hostAddr;      /* Host servicing Interrupt */
    unsigned int    hostPort;      /* valid port # on client */
    unsigned int    progNum;       /* DEVICE_INTR */
    unsigned int    progVers;      /* DEVICE_INTR_VERSION */
    Device_AddrFamily   progFamily; /* DEVICE_UDP | DEVICE_TCP */
};
struct Device_EnableSrqParms    {
    Device_Link           lid;
    bool                  enable;     /* Enable or disable interrupts */
    opaque                handle<40>; /* Host specific data */
};
struct Device_LockParms {
    Device_Link    lid;           /* link id from create_link */
    Device_Flags   flags;         /* Contains the waitlock flag */
    unsigned int  lock_timeout;  /* time to wait to acquire lock */
};
struct Device_DocmdParms {
    Device_Link    lid;           /* link id from create_link */
    Device_Flags   flags;         /* flags specifying various options */
    unsigned int  io_timeout;    /* time to wait for I/O to complete */
    unsigned int  lock_timeout;  /* time to wait on a lock */
    int           cmd;           /* which command to execute */
    bool           network_order; /* client's byte order */
    int           datasize;      /* size of individual data elements */
    opaque         data_in<>;     /* docmd data parameters */
};
struct Device_DocmdResp {
    Device_ErrorCode   error;       /* returned status */
    opaque             data_out<>;  /* returned data parameter */
};
program DEVICE_ASYNC{
    version DEVICE_ASYNC_VERSION {
       Device_Error      device_abort (Device_Link)            = 1;
     } = 1;
} = 0x0607B0;
program DEVICE_CORE {
  version DEVICE_CORE_VERSION {
    Create_LinkResp    create_link        (Create_LinkParms)      = 10;
    Device_WriteResp   device_write       (Device_WriteParms)     = 11;
    Device_ReadResp    device_read        (Device_ReadParms)      = 12;
    Device_Error       device_trigger     (Device_GenericParms)   = 14;
    Device_Error       device_clear       (Device_GenericParms)   = 15;
    Device_Error       device_remote      (Device_GenericParms)   = 16;
    Device_Error       device_local       (Device_GenericParms)   = 17;
    Device_Error       device_lock        (Device_LockParms)      = 18;
    Device_Error       device_unlock      (Device_Link)           = 19;
    Device_Error       device_enable_srq  (Device_EnableSrqParms) = 20;
    Device_DocmdResp   device_docmd       (Device_DocmdParms)     = 22;
    Device_Error       destroy_link       (Device_Link)           = 23;
    Device_Error       create_intr_chan   (Device_RemoteFunc)     = 25;
    Device_Error       destroy_intr_chan  (void)                  = 26;
     } = 1;
} = 0x0607AF;

/* Types */ 
struct Device_SrqParms { 
     opaque handle<>; 
}; 

program DEVICE_INTR { 
  version DEVICE_INTR_VERSION { 
     void                   device_intr_srq           (Device_SrqParms)          = 30; 
      }=1; 
}= 0x0607B1; 



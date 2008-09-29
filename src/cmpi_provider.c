/*****************************************************************************
* Copyright (C) 2008 Novell Inc. All rights reserved.
* Copyright (C) 2008 SUSE Linux Products GmbH. All rights reserved.
* 
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
* 
*   - Redistributions of source code must retain the above copyright notice,
*     this list of conditions and the following disclaimer.
* 
*   - Redistributions in binary form must reproduce the above copyright notice,
*     this list of conditions and the following disclaimer in the documentation
*     and/or other materials provided with the distribution.
* 
*   - Neither the name of Novell Inc. nor of SUSE Linux Products GmbH nor the
*     names of its contributors may be used to endorse or promote products
*     derived from this software without specific prior written permission.
* 
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL Novell Inc. OR SUSE Linux Products GmbH OR
* THE CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
* OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*****************************************************************************/

#include <stdio.h>
#include <stdarg.h>
#include <pthread.h>

/* Include the required CMPI macros, data types, and API function headers */
#include <cmpidt.h>
#include <cmpift.h>
#include <cmpimacs.h>

// Needed to obtain errno of failed system calls
#include <errno.h>

/* Needed for kill() */
#include <signal.h>

/* A simple stderr logging/tracing facility. */
#ifndef _SBLIM_TRACE
#define _SBLIM_TRACE(tracelevel,args) _logstderr args 
void _logstderr(char *fmt,...)
{
   va_list ap;
   va_start(ap,fmt);
   vfprintf(stderr,fmt,ap);
   va_end(ap);
   fprintf(stderr,"\n");
}
#endif


SWIGEXPORT void SWIG_init(void);
#define _CMPI_SETFAIL(msgstr) {if (st != NULL) st->rc = CMPI_RC_ERR_FAILED; st->msg = msgstr; }

/*
**==============================================================================
**
** Local definitions:
**
**==============================================================================
*/

/*
 * per-MI struct to keep
 * - name of MI
 * - pointer to target instrumentation
 * - pointer to Broker
 */

typedef struct __ProviderMIHandle
{
    char *miName;
    Target_Type tgMod;
    const CMPIBroker* broker;
} ProviderMIHandle;


/*
 * string2target
 * char* -> Target_Type
 */

static Target_Type
string2target(const char *s)
{
    if (s == NULL)
        return Target_Null;

    Target_Type obj;
    TARGET_THREAD_BEGIN_BLOCK;
 
    obj = Target_String(s);
    TARGET_THREAD_END_BLOCK; 
 
    return obj;
}


/*
 * proplist2target
 * char** -> Target_Type
 */

static Target_Type
proplist2target(const char** cplist)
{
    TARGET_THREAD_BEGIN_BLOCK;
    if (cplist == NULL)
    {
        Target_INCREF(Target_Void);
        TARGET_THREAD_END_BLOCK; 
        return Target_Void; 
    }
    Target_Type pl;
 
    pl = Target_Array(); 
    for (; (cplist!=NULL && *cplist != NULL); ++cplist)
    {
        Target_Append(pl, Target_String(*cplist)); 
    }
    TARGET_THREAD_END_BLOCK; 
 
    return pl; 
}


static char *
fmtstr(const char* fmt, ...)
{
    va_list ap; 
    int len; 
    va_start(ap, fmt); 
    len = vsnprintf(NULL, 0, fmt, ap); 
    va_end(ap); 
    if (len <= 0)
    {
        return NULL; 
    }
    char* str = (char*)malloc(len+1); 
    if (str == NULL)
    {
        return NULL; 
    }
    va_start(ap, fmt); 
    vsnprintf(str, len+1, fmt, ap); 
    va_end(ap); 
    return str; 
}


/*
**==============================================================================
**
** Local definitions:
**
**==============================================================================
*/

static int _MI_COUNT = 0; 

/* on-demand init */
#define TARGET_CMPI_INIT { if (((ProviderMIHandle*)(self->hdl))->tgMod == Target_Null) if (TargetInitialize(((ProviderMIHandle*)(self->hdl)), &status) != 0) return status; }

#if defined(SWIGPYTHON)
#include "target_python.c"
#endif

#if defined(SWIGRUBY)
#include "target_ruby.c"
#endif

/*
 * Cleanup
 * 
 */

static CMPIStatus
Cleanup(
        ProviderMIHandle * miHdl,
        const CMPIContext * context,
        CMPIBoolean terminating)    
{
    CMPIStatus status = {CMPI_RC_OK, NULL}; /* Return status of CIM operations. */
  
    if (miHdl != NULL) 
    { 
        free(miHdl->miName); 
     
        // we must free the miHdl - it is our ProviderMIHandle.
        // it is pointed to by the CMPI<type>MI * that the broker holds onto...
        // the broker is responsible for freeing the CMPI<type>MI*  
        free(miHdl);
        miHdl = NULL; 
    }
  
    TargetCleanup();

    _SBLIM_TRACE(1,("Cleanup() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
**==============================================================================
**
** Provider Interface functions
**
**==============================================================================
*/

/*
 * InstCleanup
 */

static CMPIStatus
InstCleanup(CMPIInstanceMI * self,      
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    _SBLIM_TRACE(1,("Cleanup() called for Instance provider %s", ((ProviderMIHandle *)self->hdl)->miName));
    CMPIStatus st = Cleanup((ProviderMIHandle*)self->hdl, context, terminating); 
    return st;
}


/*
 * AssocCleanup
 */

static CMPIStatus
AssocCleanup(CMPIAssociationMI * self,   
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    _SBLIM_TRACE(1,("Cleanup() called for Association provider %s", ((ProviderMIHandle *)self->hdl)->miName));
    CMPIStatus st = Cleanup((ProviderMIHandle*)self->hdl, context, terminating); 
    return st;
}


/*
 * MethodCleanup
 */

static CMPIStatus
MethodCleanup(CMPIMethodMI * self,    
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    _SBLIM_TRACE(1,("Cleanup() called for Method provider %s", ((ProviderMIHandle *)self->hdl)->miName));
    CMPIStatus st = Cleanup((ProviderMIHandle*)self->hdl, context, terminating); 
    return st;
}


/*
 * IndicationCleanup
 */

static CMPIStatus
IndicationCleanup(CMPIIndicationMI * self,    
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    _SBLIM_TRACE(1,("Cleanup() called for Indication provider %s", ((ProviderMIHandle *)self->hdl)->miName));
    CMPIStatus st = Cleanup((ProviderMIHandle*)self->hdl, context, terminating); 
    return st;
}

// ----------------------------------------------------------------------------


/*
 * EnumInstanceNames() - return a list of all the instances names (i.e. return their object paths only)
 */
static CMPIStatus
EnumInstanceNames(CMPIInstanceMI * self,      
        const CMPIContext * context,
        const CMPIResult * result,
        const CMPIObjectPath * reference)
{
    CMPIStatus status = {CMPI_RC_OK, NULL};

    _SBLIM_TRACE(1,("EnumInstancesNames() called, context %p, result %p, reference %p", context, result, reference));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _result = SWIG_NewPointerObj((void*) result, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 

    call_provider((ProviderMIHandle*)self->hdl, &status, "enum_instance_names", 3, 
                                                        _context,
                                                        _result,
                                                        _reference); 

   _SBLIM_TRACE(1,("EnumInstanceNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/*
 * EnumInstances() - return a list of all the instances (i.e. return all the instance data)
 */
static CMPIStatus
EnumInstances(CMPIInstanceMI * self,  
        const CMPIContext * context,
        const CMPIResult * result,
        const CMPIObjectPath * reference,
        const char ** properties)
{
    CMPIStatus status = {CMPI_RC_OK, NULL};  /* Return status of CIM operations */
    /*   char * namespace = CMGetCharPtr(CMGetNameSpace(reference, NULL));  Our current CIM namespace */

    _SBLIM_TRACE(1,("EnumInstances() called, context %p, result %p, reference %p, properties %p", context, result, reference, properties));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _result = SWIG_NewPointerObj((void*) result, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type _properties = proplist2target(properties); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "enum_instances", 4, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _properties); 

   _SBLIM_TRACE(1,("EnumInstances() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/*
 * GetInstance() -  return the instance data for the specified instance only
 */
static CMPIStatus
GetInstance(CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const char ** properties)
{
    CMPIStatus status = {CMPI_RC_OK, NULL};  /* Return status of CIM operations */

    _SBLIM_TRACE(1,("GetInstance() called, context %p, results %p, reference %p, properties %p", context, results, reference, properties));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type _properties = proplist2target(properties); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "get_instance", 4, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _properties); 

   _SBLIM_TRACE(1,("GetInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/*
 * CreateInstance() - create a new instance from the specified instance data.
 */
static CMPIStatus
CreateInstance(CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const CMPIInstance * newinstance)
{
   CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */
   
   /* Creating new instances is not supported for this class. */
  
    _SBLIM_TRACE(1,("CreateInstance() called, context %p, results %p, reference %p, newinstance %p", context, results, reference, newinstance));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    Target_Type _newinst = SWIG_NewPointerObj((void*) newinstance, SWIGTYPE_p__CMPIInstance, 0);
    TARGET_THREAD_END_BLOCK; 

    call_provider((ProviderMIHandle*)self->hdl, &status, "create_instance", 4, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _newinst); 

   _SBLIM_TRACE(1,("CreateInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------

#ifdef CMPI_VER_100
#define SetInstance ModifyInstance
#endif

/*
 * SetInstance() - save modified instance data for the specified instance.
 */
static CMPIStatus
SetInstance(CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results, 
        const CMPIObjectPath * reference,
        const CMPIInstance * newinstance,
        const char ** properties)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */
   
   /* Modifying existing instances is not supported for this class. */
 
    _SBLIM_TRACE(1,("SetInstance() called, context %p, results %p, reference %p, newinstance %p, properties %p", context, results, reference, newinstance, properties));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    Target_Type _newinst = SWIG_NewPointerObj((void*) newinstance, SWIGTYPE_p__CMPIInstance, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type plist = proplist2target(properties); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "set_instance", 5, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _newinst,
                                                               plist); 
  
   _SBLIM_TRACE(1,("SetInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/* ---------------------------------------------------------------------------- */

/*
 * DeleteInstance() - delete/remove the specified instance.
 */
static CMPIStatus
DeleteInstance(CMPIInstanceMI * self,  
        const CMPIContext * context,
        const CMPIResult * results, 
        const CMPIObjectPath * reference)
{
    CMPIStatus status = {CMPI_RC_OK, NULL};  

    _SBLIM_TRACE(1,("DeleteInstance() called, context %p, results %p, reference %p", context, results, reference));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 

    call_provider((ProviderMIHandle*)self->hdl, &status, "delete_instance", 3, 
                                                               _context,
                                                               _result, 
                                                               _reference); 
  
   _SBLIM_TRACE(1,("DeleteInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/* ---------------------------------------------------------------------------- */

/*
 * ExecQuery() - return a list of all the instances that satisfy the desired query filter.
 */
static CMPIStatus
ExecQuery(CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const char * query,
        const char * language)  
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */
   
    _SBLIM_TRACE(1,("ExecQuery() called, context %p, results %p, reference %p, query %s, language %s", context, results, reference, query, language));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type _query = string2target(query); 
    Target_Type _lang = string2target(language); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "exec_query", 5, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _query,
                                                               _lang); 

   /* Query filtering is not supported for this class. */

   _SBLIM_TRACE(1,("ExecQuery() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/* ---------------------------------------------------------------------------- 
 * CMPI external API
 * ---------------------------------------------------------------------------- */

/*
 * associatorMIFT
 */

CMPIStatus
associatorNames(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* assocClass,
        const char* resultClass,
        const char* role,
        const char* resultRole)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("associatorNames() called, ctx %p, rslt %p, objName %p, assocClass %s, resultClass %s, role %s, resultRole %s", ctx, rslt, objName, assocClass, resultClass, role, resultRole));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type _assocClass = Target_Null; 
    Target_Type _resultClass = Target_Null; 
    Target_Type _role = Target_Null; 
    Target_Type _resultRole = Target_Null;
    if (assocClass != NULL)
    {
        _assocClass = string2target(assocClass); 
    }
    if (resultClass != NULL)
    {
        _resultClass = string2target(resultClass); 
    }
    if (role != NULL) 
    { 
        _role = string2target(role); 
    }
    if (resultRole != NULL) 
    { 
        _resultRole = string2target(resultRole); 
    }

    call_provider((ProviderMIHandle*)self->hdl, &status, "associator_names", 7, 
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _assocClass,
                                                               _resultClass,
                                                               _role,
                                                               _resultRole); 


   _SBLIM_TRACE(1,("associatorNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/*
 * associators
 */

CMPIStatus
associators(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* assocClass,
        const char* resultClass,
        const char* role,
        const char* resultRole,
        const char** properties)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("associators() called, ctx %p, rslt %p, objName %p, assocClass %s, resultClass %s, role %s, resultRole %s", ctx, rslt, objName, assocClass, resultClass, role, resultRole));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type _props = proplist2target(properties); 
    Target_Type _assocClass = Target_Null;
    Target_Type _resultClass = Target_Null;
    Target_Type _role = Target_Null;
    Target_Type _resultRole = Target_Null;
    if (assocClass != NULL)
    {
        _assocClass = string2target(assocClass); 
    }
    if (resultClass != NULL)
    {
        _resultClass = string2target(resultClass); 
    }
    if (role != NULL) 
    { 
        _role = string2target(role); 
    }
    if (resultRole != NULL) 
    { 
        _resultRole = string2target(resultRole); 
    }

    call_provider((ProviderMIHandle*)self->hdl, &status, "associators", 8, 
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _assocClass,
                                                               _resultClass,
                                                               _role,
                                                               _resultRole,
                                                               _props); 


   _SBLIM_TRACE(1,("associators() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/*
 * referenceNames
 */

CMPIStatus
referenceNames(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* resultClass,
        const char* role)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("referenceNames() called, ctx %p, rslt %p, objName %p, resultClass %s, role %s", ctx, rslt, objName, resultClass, role));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK;
    Target_Type _resultClass = Target_Null;
    Target_Type _role = Target_Null;
    if (role != NULL) 
    { 
        _role = string2target(role); 
    }
    if (resultClass != NULL) 
    { 
        _resultClass = string2target(resultClass); 
    }

    call_provider((ProviderMIHandle*)self->hdl, &status, "reference_names", 5,
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _resultClass,
                                                               _role); 


   _SBLIM_TRACE(1,("referenceNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/*
 * references
 */

CMPIStatus
references(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* resultClass,
        const char* role,
        const char** properties)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("references() called, ctx %p, rslt %p, objName %p, resultClass %s, role %s, properties %p", ctx, rslt, objName, resultClass, role, properties));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK;
    Target_Type _role = Target_Null;
    Target_Type _resultClass = Target_Null;
    if (role != NULL) 
    { 
        _role = string2target(role); 
    }
    if (resultClass != NULL) 
    { 
        _resultClass = string2target(resultClass); 
    }
    Target_Type _props = proplist2target(properties); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "references", 6, 
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _resultClass,
                                                               _role,
                                                               _props); 

   _SBLIM_TRACE(1,("references() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/*
 * invokeMethod
 */
CMPIStatus
invokeMethod(
        CMPIMethodMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* method,
        const CMPIArgs* in,
        CMPIArgs* out)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("invokeMethod() called, ctx %p, rslt %p, objName %p, method %s, in %p, out %p", ctx, rslt, objName, method, in, out));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    Target_Type _in = SWIG_NewPointerObj((void*) in, SWIGTYPE_p__CMPIArgs, 0);
    Target_Type _out = SWIG_NewPointerObj((void*) out, SWIGTYPE_p__CMPIArgs, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type _method = string2target(method); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "invoke_method", 6, 
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _method,
                                                               _in,
                                                               _out); 

   _SBLIM_TRACE(1,("invokeMethod() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/*
 * authorizeFilter
 */

CMPIStatus authorizeFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        const char* owner)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
  
    _SBLIM_TRACE(1,("authorizeFilter() called, ctx %p, filter %p, className %s, classPath %p, owner %s", ctx, filter, className, classPath, owner)); 

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _filter = SWIG_NewPointerObj((void*) filter, SWIGTYPE_p__CMPISelectExp, 0);
    Target_Type _classPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type _className = string2target(className); 
    Target_Type _owner = string2target(owner); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "authorize_filter", 5, 
                                                               _ctx,
                                                               _filter, 
                                                               _className,
                                                               _classPath,
                                                               _owner);

   _SBLIM_TRACE(1,("authorizeFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/*
 * activateFilter
 */

CMPIStatus activateFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        CMPIBoolean firstActivation)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("activateFilter() called, ctx %p, filter %p, className %s, classPath %p, firstActivation %d", ctx, filter, className, classPath, firstActivation));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _filter = SWIG_NewPointerObj((void*) filter, SWIGTYPE_p__CMPISelectExp, 0);
    Target_Type _classPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    Target_Type _firstActivation = Target_Bool(firstActivation); 
    TARGET_THREAD_END_BLOCK; 
    Target_Type _className = string2target(className); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "activate_filter", 5, 
                                                               _ctx,
                                                               _filter, 
                                                               _className,
                                                               _classPath,
                                                               _firstActivation);

   _SBLIM_TRACE(1,("activateFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/*
 * deActivateFilter
 */

CMPIStatus deActivateFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        CMPIBoolean lastActivation)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("deActivateFilter() called, ctx %p, filter %p, className %s, classPath %p, lastActivation %d", ctx, filter, className, classPath, lastActivation));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    Target_Type _filter = SWIG_NewPointerObj((void*) filter, SWIGTYPE_p__CMPISelectExp, 0);
    Target_Type _classPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    Target_Type _lastActivation = Target_Bool(lastActivation); 
    TARGET_THREAD_END_BLOCK; 
    Target_Type _className = string2target(className); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "deactivate_filter", 5, 
                                                               _ctx,
                                                               _filter, 
                                                               _className,
                                                               _classPath,
                                                               _lastActivation);

   _SBLIM_TRACE(1,("deActivateFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/*
 * mustPoll
 * Note: sfcb doesn't support mustPoll. :(
 * http://sourceforge.net/mailarchive/message.php?msg_id=OFF38FF3F9.39FD2E1F-ONC1257385.004A7122-C1257385.004BB0AF%40de.ibm.com
 */
CMPIStatus
mustPoll(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        //const CMPIResult* rslt, TODO: figure out who is right: spec. vs. sblim
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    //_SBLIM_TRACE(1,("mustPoll() called, ctx %p, rslt %p, filter %p, className %s, classPath %p", ctx, rslt, filter, className, classPath));
    _SBLIM_TRACE(1,("mustPoll() called, ctx %p, filter %p, className %s, classPath %p", ctx, filter, className, classPath));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    //Target_Type _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    Target_Type _filter = SWIG_NewPointerObj((void*) filter, SWIGTYPE_p__CMPISelectExp, 0);
    Target_Type _classPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    TARGET_THREAD_END_BLOCK; 
    Target_Type _className = string2target(className); 

    call_provider((ProviderMIHandle*)self->hdl, &status, "must_poll", 4, 
                                                               _ctx,
                                                               //_rslt,
                                                               _filter, 
                                                               _className,
                                                               _classPath);

   _SBLIM_TRACE(1,("mustPoll() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/*
 * enableIndications
 */

CMPIStatus
enableIndications(
        CMPIIndicationMI* self,
        const CMPIContext* ctx)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("enableIndications() called, ctx %p", ctx));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    TARGET_THREAD_END_BLOCK; 

    call_provider((ProviderMIHandle*)self->hdl, &status, "enable_indications", 1, _ctx); 

   _SBLIM_TRACE(1,("enableIndications() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;

}


/*
 * disableIndications
 */

CMPIStatus 
disableIndications(
        CMPIIndicationMI* self,
        const CMPIContext* ctx)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("disableIndications() called, ctx %p", ctx));

    TARGET_CMPI_INIT

    TARGET_THREAD_BEGIN_BLOCK; 
    Target_Type _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    TARGET_THREAD_END_BLOCK; 

    call_provider((ProviderMIHandle*)self->hdl, &status, "disable_indications", 1, _ctx); 

   _SBLIM_TRACE(1,("disableIndications() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;

}


/***************************************************************************/

/* MI function tables */

static CMPIMethodMIFT MethodMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "methodCmpi_Swig",  // miName
    MethodCleanup, 
    invokeMethod, 
}; 


static CMPIIndicationMIFT IndicationMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "indicationCmpi_Swig",  // miName
    IndicationCleanup, 
    authorizeFilter, 
    mustPoll, 
    activateFilter, 
    deActivateFilter, 
    enableIndications, 
    disableIndications, 
}; 


static CMPIAssociationMIFT AssociationMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "instanceCmpi_Swig",  // miName
    AssocCleanup, 
    associators, 
    associatorNames, 
    references, 
    referenceNames, 
}; 


static CMPIInstanceMIFT InstanceMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "associatorCmpi_Swig",  // miName
    InstCleanup, 
    EnumInstanceNames, 
    EnumInstances, 
    GetInstance, 
    CreateInstance, 
    SetInstance, 
    DeleteInstance, 
    ExecQuery, 
}; 


static void
createInit(const CMPIBroker* broker, 
        const CMPIContext* context, const char* miname, CMPIStatus* st)
{
    _SBLIM_TRACE(1,("\n>>>>> createInit() called, miname= %s (ctx=%p)\n", miname, context));
  
   /*
    * We can't initialize the target here and load target modules, because
    * SFCB passes a NULL CMPIStatus* st, which means we can't report 
    * back error strings.  Instead, we'll check and initialize in each
    * MIFT function
    */ 
}


#define SWIG_CMPI_MI_FACTORY(ptype) \
CMPI##ptype##MI* _Generic_Create_##ptype##MI(const CMPIBroker* broker, \
        const CMPIContext* context, const char* miname, CMPIStatus* st)\
{ \
    _SBLIM_TRACE(1, ("\n>>>>> in FACTORY: CMPI"#ptype"MI* _Generic_Create_"#ptype"MI... miname=%s", miname)); \
    ProviderMIHandle *hdl = (ProviderMIHandle*)malloc(sizeof(ProviderMIHandle)); \
    if (hdl) { \
        hdl->tgMod = Target_Null; \
        hdl->miName = strdup(miname); \
        hdl->broker = broker; \
    } \
    CMPI##ptype##MI *mi= (CMPI##ptype##MI*)malloc(sizeof(CMPI##ptype##MI)); \
    if (mi) { \
        mi->hdl = hdl; \
        mi->ft = &ptype##MIFT__; \
    } \
    createInit(broker, context, miname, st); \
    /*_SBLIM_TRACE(1, ("\n>>>>>     returning mi=0x%08x  mi->hdl=0x%08x   mi->ft=0x%08x", mi, mi->hdl, mi->ft));*/ \
    ++_MI_COUNT; \
    return mi; \
}

SWIG_CMPI_MI_FACTORY(Instance)
SWIG_CMPI_MI_FACTORY(Method)
SWIG_CMPI_MI_FACTORY(Association)
SWIG_CMPI_MI_FACTORY(Indication)

#undef _CMPI_SETFAIL
#undef TARGET_THREAD_BEGIN_BLOCK
#undef TARGET_THREAD_END_BLOCK
#undef TARGET_THREAD_BEGIN_ALLOW
#undef TARGET_THREAD_END_ALLOW
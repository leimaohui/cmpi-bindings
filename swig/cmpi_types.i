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

# cmpift.i
#
# swig bindings for CMPI function tables
#

#
# Prevent default con-/destructors for all types
# CMPI types are handled through function tables
# and the broker.
#

%nodefault CMPIError;
%rename(CMPIError) _CMPIError;
typedef struct _CMPIError {} CMPIError;

%nodefault _CMPIResult;
%rename(CMPIResult) _CMPIResult;
typedef struct _CMPIResult {} CMPIResult;

%nodefault _CMPIMsgFileHandle;
%rename(CMPIMsgFileHandle) _CMPIMsgFileHandle;
typedef struct _CMPIMsgFileHandle {} CMPIMsgFileHandle;

%nodefault _CMPIObjectPath;
%rename(CMPIObjectPath) _CMPIObjectPath;
typedef struct _CMPIObjectPath {} CMPIObjectPath;

%nodefault _CMPIInstance;
%rename(CMPIInstance) _CMPIInstance;
typedef struct _CMPIInstance {} CMPIInstance;

%nodefault _CMPIArgs;
%rename(CMPIArgs) _CMPIArgs;
typedef struct _CMPIArgs {} CMPIArgs;

%nodefault _CMPISelectExp;
%rename(CMPISelectExp) _CMPISelectExp;
typedef struct _CMPISelectExp {} CMPISelectExp;

%nodefault _CMPISelectCond;
%rename(CMPISelectCond) _CMPISelectCond;
typedef struct _CMPISelectCond {} CMPISelectCond;

%nodefault _CMPISubCond;
%rename(CMPISubCond) _CMPISubCond;
typedef struct _CMPISubCond {} CMPISubCond;

%nodefault _CMPIPredicate;
%rename(CMPIPredicate) _CMPIPredicate;
typedef struct _CMPIPredicate {} CMPIPredicate;

%nodefault _CMPIEnumeration;
%rename(CMPIEnumeration) _CMPIEnumeration;
typedef struct _CMPIEnumeration {} CMPIEnumeration;

%nodefault _CMPIArray;
%rename(CMPIArray) _CMPIArray;
typedef struct _CMPIArray {} CMPIArray;

%nodefault _CMPIString;
%rename(CMPIString) _CMPIString;
typedef struct _CMPIString {} CMPIString;

%nodefault _CMPIContext;
%rename(CMPIContext) _CMPIContext;
typedef struct _CMPIContext {} CMPIContext;

%nodefault _CMPIDateTime;
%rename(CMPIDateTime) _CMPIDateTime;
typedef struct _CMPIDateTime {} CMPIDateTime;

#-----------------------------------------------------
#
# CMPIException
#
#-----------------------------------------------------

%nodefault _CMPIException;
%rename(CMPIException) CMPIException;
typedef struct _CMPIException {} CMPIException;

/*
 *
 * Container for a fault, contains numeric error_code and textual
 * description
 *
 */
%extend CMPIException 
{
  CMPIException() 
  {
      return (CMPIException*)calloc(1, sizeof(CMPIException));
  }

  ~CMPIException() 
  {
      free($self->description);
  }
#if defined(SWIGRUBY)
%rename("error_code") get_error_code();
#endif
  /*
   * Numerical error code
   *
   */
  int get_error_code() 
  {
    return $self->error_code;
  }

#if defined(SWIGRUBY)
%rename("description") get_description();
#endif
  /*
   * Textual error description
   *
   */
  const char* get_description() 
  {
    return $self->description;
  }
}

#-----------------------------------------------------
#
# %exception
#
#-----------------------------------------------------

#ifdef SWIGPYTHON
%exception 
{
    _clr_raised();
    $action
    if (_get_raised())
    {
        _clr_raised();
#if SWIG_VERSION < 0x020000
        SWIG_PYTHON_THREAD_END_ALLOW;
#endif
        SWIG_fail;
    }
}
#endif /* SWIGPYTHON */

#-----------------------------------------------------
#
# CMPIError
#

/*
 * Document-class: CMPIError
 *
 */
%extend _CMPIError 
{
  ~CMPIError() { }

/* Gets the type of this Error */
  CMPIErrorType type() {
    return CMGetErrorType($self, NULL);
  }

#if defined(SWIGRUBY)
  %rename("type=") set_type(const CMPIErrorType et);
#endif
  /* Sets the error type of this error object. */
  void set_type(const CMPIErrorType et) {
    CMSetErrorType($self, et);
  }

/* Returns a string which describes the alternate error type. */
  const char *other_type() {
    return CMGetCharPtr(CMGetOtherErrorType($self, NULL));
  }

#if defined(SWIGRUBY)
  %rename("other_type=") set_other_type(const char *ot);
#endif
  /* Sets the 'other' error type of this error object. */
  void set_other_type(const char *ot) {
    CMSetOtherErrorType($self, ot);
  }

  /* Returns a string which describes the owning entity. */
  const char *owning_entity() {
    return CMGetCharPtr(CMGetOwningEntity($self, NULL));
  }
  
  /* Returns a string which is the message ID. */
  const char *message_id() {
    return CMGetCharPtr(CMGetMessageID($self, NULL));
  }
  
  /* Returns a string comnating an error message. */
  const char *message() {
    return CMGetCharPtr(CMGetErrorMessage($self, NULL));
  }
  
  /* Returns the perceieved severity of this error. */
  CMPIErrorSeverity severity() {
    return CMGetPerceivedSeverity($self, NULL);
  }
  
  /* Returns the probable cause of this error. */
  CMPIErrorProbableCause probable_cause() {
    return CMGetProbableCause($self, NULL);
  }
  
#if defined(SWIGRUBY)
  %rename("probable_cause=") set_probable_cause(const char *pcd);
#endif
  /* Sets the description of the probable cause. */
  void set_probable_cause(const char *pcd) {
    CMSetProbableCauseDescription($self, pcd);
  }
  
  /* Returns a string which describes the probable cause. */
  const char *probable_cause_description() {
    return CMGetCharPtr(CMGetProbableCauseDescription($self, NULL));
  }
  
  /* Returns an array of strings which describes recomended actions. */
  CMPIArray *recommended_actions() {
    return CMGetRecommendedActions($self, NULL);
  }
  
#if defined(SWIGRUBY)
  %rename("recommended_actions=") set_recommended_actions(const CMPIArray* ra);
#endif
  /* Sets the recomended actions array. */
  void set_recommended_actions(const CMPIArray* ra) {
    CMSetRecommendedActions($self, ra);
  }
  
  /* Returns a string which describes the Error source. */
  const char *source() {
    return CMGetCharPtr(CMGetErrorSource($self, NULL));
  }
  
#if defined(SWIGRUBY)
  %rename("source=") set_source(const char *es);
#endif
  /* Specifies a string which specifes The identifying information of
     the entity (i.e., the instance) generating the error. */
  void set_source(const char *es) {
    CMSetErrorSource($self, es);
  }
  
  /* Returns a the format that the error src is in. */
  CMPIErrorSrcFormat source_format() {
    return CMGetErrorSourceFormat($self, NULL);
  }

#if defined(SWIGRUBY)
  %rename("source_format=") set_source_format(const CMPIErrorSrcFormat esf);
#endif
  /* Sets the source format of the error object. */
  void set_source_format(const CMPIErrorSrcFormat esf) {
    CMSetErrorSourceFormat($self, esf);
  }
  
  /* Returns a string which describes the 'other' format, only
     available if the error source is OTHER. */
  const char *other_format() {
    return CMGetCharPtr(CMGetOtherErrorSourceFormat($self, NULL));
  }
  
#if defined(SWIGRUBY)
  %rename("other_format=") set_other_format(const char *oesf);
#endif
  /* specifies A string defining "Other" values for ErrorSourceFormat */
  void set_other_format(const char *oesf) {
    CMSetOtherErrorSourceFormat($self, oesf);
  }
  
  /* Returns the status code of this error. */
  CMPIrc status_code() {
    return CMGetCIMStatusCode($self, NULL);
  }
  
  /* Returns a string which describes the status code error. */
  const char *status_description() {
    return CMGetCharPtr(CMGetCIMStatusCodeDescription($self, NULL));
  }
  
#if defined(SWIGRUBY)
  %rename("status_description=") set_status_description(const char *cd);
#endif
  /* Sets the description of the status code. */
  void set_status_description(const char *cd) {
    CMSetCIMStatusCodeDescription($self, cd);
  }
  
  /* Returns an array which contains the dynamic content of the message. */
  CMPIArray *message_arguments() {
    return CMGetMessageArguments($self, NULL);
  }

#if defined(SWIGRUBY)
  %rename("message_arguments=") set_message_arguments(CMPIArray* ma);
#endif
  /* Sets an array of strings for the dynamic content of the message. */
  void set_message_arguments(CMPIArray* ma) {
    CMSetMessageArguments($self, ma);
  }
}

#-----------------------------------------------------
#
# CMPIResult
#

/*
 * Document-class: CMPIResult
 *
 */
%extend _CMPIResult 
{
  /* no con-/destructor, the broker handles this */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  /* Return string representation */
  const char* string() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIString* result;
    const CMPIBroker* broker = cmpi_broker();

    result = CDToString(broker, $self, &st);
    RAISE_IF(st);

    return CMGetCharPtr(result);
  }
#endif

  /* Add the +instance+ to the result */
  void return_instance(CMPIInstance *instance) 
  {
    RAISE_IF(CMReturnInstance($self, instance));
  }

  /* Add the +objectpath+ to the result */
  void return_objectpath(CMPIObjectPath *path) 
  {
    RAISE_IF(CMReturnObjectPath($self, path));
  }

  /* Add typed value to the result */
  void return_data(const CMPIValue* value, const CMPIType type) 
  {
    RAISE_IF(CMReturnData($self, value, type));
  }

  void done() 
  {
    RAISE_IF(CMReturnDone($self));
  }
}

#-----------------------------------------------------
#
# CMPIObjectPath
#

/*
 * Document-class: CMPIObjectPath
 *
 */
%extend _CMPIObjectPath 
{
#if HAVE_CMPI_BROKER
  CMPIObjectPath(const char *ns, const char *cn = NULL)
#else
  CMPIObjectPath(const CMPIBroker* broker, const char *ns, const char *cn = NULL)
#endif
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
#if HAVE_CMPI_BROKER
    const CMPIBroker* broker = cmpi_broker();
#endif
    if (cn == NULL) { /* assume creating from string representation */
      /* parse <namespace>:<classname>[.<key>=<value>[,<key>=<value>]...] */
      CMPIObjectPath *path;
      const char *ptr;
      
      /* find and extract namespace */
      ptr = strchr(ns, ':');
      if (ptr == NULL)
        return NULL; /* should raise */
      ns = strndup(ns, ptr-ns);
      
      /* find and extract classname */
      cn = ++ptr;
      ptr = strchr(cn, '.');
      if (ptr == NULL)
        return NULL; /* should raise */
      path = CMNewObjectPath( broker, ns, cn, &st );
      /* find and extract properties */
      ptr++;
      while (*ptr) {
        const char *key;
	const char *val;
	
	key = ptr;
	ptr = strchr(key, '=');
	if (ptr == NULL)
          return NULL; /* should raise */
	val = ++ptr;
	if (*val == '"') {
	  val++;
	  ptr = val;
	  for (;;) {
	    ptr = strchr(ptr, '"');
	    if (ptr == NULL)
	      return NULL; /* should raise */
	    if (*(ptr-1) != '\\') /* not escaped " */
	      break;
	    ptr++;
	  }
	  val = strndup(val, ptr-val);
	}
	else {
	  ptr = strchr(ptr, ',');
	  val = strndup(val, ptr-val);
	}
	ptr++;
	CMAddKey(path, key, val, CMPI_string);
      }
      return path;
    }
    return CMNewObjectPath( broker, ns, cn, &st );
  }

  ~CMPIObjectPath() 
  { 
  }

  /**
   * Create an independent copy of this ObjectPath object. The resulting
   *          object must be released explicitly.
FIXME: if clone() is exposed, release() must also
  CMPIObjectPath *clone() {
    return $self->ft->clone($self, NULL);
  }
   */     

#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  /* Return string representation */
  const char *string()
  {
    return CMGetCharPtr($self->ft->toString($self, NULL));
  }
  
#if defined(SWIGRUBY)
  %alias set "[]=";
  /*
   * Key setting in Ruby
   * instance[:propname] = data    # set by name (symbol)
   * instance["propname"] = data   # set by name (string)
   */
  CMPIStatus set(VALUE property, VALUE data)
  {
    const char *name;
    CMPIValue *value = (CMPIValue *)malloc(sizeof(CMPIValue));
    CMPIType type;
    if (SYMBOL_P(property)) {
      name = rb_id2name(SYM2ID(property));
    }
    else {
      name = StringValuePtr(property);
    }
    switch (TYPE(data)) {
      case T_FLOAT:
        value->Float = RFLOAT(data)->value;
        type = CMPI_real32;
      break;
      case T_STRING:
        value->string = to_cmpi_string(data);
        type = CMPI_string;
      break; 
      case T_FIXNUM:
        value->Int = FIX2ULONG(data);
        type = CMPI_uint32;
      break;
      case T_TRUE:
        value->boolean = 1;
        type = CMPI_boolean;
      break;
      case T_FALSE:
        value->boolean = 0;
        type = CMPI_boolean;
      break;
      case T_SYMBOL:
        value->string = to_cmpi_string(data);
        type = CMPI_string;
      break;
      default:
        value->chars = NULL;
        type = CMPI_null;
        break;
    }
    return CMAddKey($self, name, value, type);
  }
#endif

  /* Adds/replaces a named key property.
   * name: Key property name.
   * value: Address of value structure.
   * type: Value type.
   */
  void add_key(
      const char *name, 
      const CMPIValue* value, 
      const CMPIType type) 
  {
    RAISE_IF(CMAddKey($self, name, value, type));
  }

#if defined(SWIGRUBY)
  %rename("key") get_key(const char *name);
#endif
  /* Gets a named key property value.
   * name: Key property name.
   */
  CMPIData get_key(const char *name) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;
    result = CMGetKey($self, name, &st);
    RAISE_IF(st);

    return result;
  }

#if defined (SWIGRUBY)
  %rename("key_at") get_key_at(int index);
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
#if defined (SWIGPERL)
  SV* 
#endif
  /* Gets a key property value defined by its index.
   * name: [out] Key property name
   */
  __type get_key_at(int index) {
    Target_Type tdata;
    CMPIString *s = NULL;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data = CMGetKeyAt($self, index, &s, &st);
    Target_Type result = Target_Null;
    if (st.rc)
    {
        RAISE_IF(st);
        return result;
    }

    TARGET_THREAD_BEGIN_BLOCK;
    tdata = SWIG_NewPointerObj((void*) data_clone(&data), SWIGTYPE_p__CMPIData, 1);
#if defined (SWIGPYTHON)
    result = PyTuple_New(2);
    PyTuple_SetItem(result, 0, tdata);
    PyTuple_SetItem(result, 1, PyString_FromString(CMGetCharPtr(s)));
#else
    result = Target_SizedArray(2);
    Target_Append(result, tdata);
    Target_Append(result, Target_String(CMGetCharPtr(s)));
#endif
    TARGET_THREAD_END_BLOCK;
    return result;
  }

  /* Gets the number of key properties contained in this ObjectPath. */
  int key_count() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    int result;

    result = CMGetKeyCount($self, &st);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  /* iterate over keys as [<value>,<name>] pairs */
  void each()
  {
    int i;
    int count = CMGetKeyCount($self, NULL);
    CMPIString *name;
    for (i = 0; i < count; ++i )
    {
      VALUE yield = rb_ary_new2(2);
      name = NULL;
      CMPIData data = CMGetKeyAt($self, i, &name, NULL);
      VALUE rbdata = SWIG_NewPointerObj((void*) data_clone(&data), SWIGTYPE_p__CMPIData, 1);
      rb_ary_push(yield, rbdata);
      rb_ary_push(yield, rb_str_new2(CMGetCharPtr(name)));
      
      rb_yield(yield);
    }
  }
#endif
#if defined(SWIGPYTHON)
      %pythoncode %{
        def keys(self):
            for i in xrange(0, self.key_count()):
                yield self.get_key_at(i)
      %}
#endif

  /* Set/replace namespace and classname components from +src+. */
  void replace_from(const CMPIObjectPath * src) 
  {
    RAISE_IF(CMSetNameSpaceFromObjectPath($self, src));
  }

  /* Set/replace hostname, namespace and classname components from +src+. 
  */
  void replace_all_from(const CMPIObjectPath * src) 
  {
    RAISE_IF(CMSetHostAndNameSpaceFromObjectPath($self, src));
  }

  /* Get class qualifier value.
   * +qName+: Qualifier name.
   */
  CMPIData qualifier(const char *qname) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetClassQualifier($self, qname, &st);
    RAISE_IF(st);

    return result;
  }

  /* Get property qualifier value.
   * +pName+: Property name.
   * +qName+: Qualifier name.
   */
  CMPIData property_qualifier(const char *pName, const char *qName) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetPropertyQualifier($self, pName, qName, &st);
    RAISE_IF(st);

    return result;
  }

  /* Get method qualifier value.
   * mName: Method name.
   * qName: Qualifier name.
   */
  CMPIData method_qualifier(const char *methodName, const char *qName) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetMethodQualifier($self, methodName, qName, &st);
    RAISE_IF(st);

    return result;
  }

  /* Get method parameter qualifier value.
   * mName: Method name.
   * pName: Parameter name.
   * qName: Qualifier name.
   */
  CMPIData parameter_qualifier(
      const char *mName, 
      const char *pName, 
      const char *qName) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetParameterQualifier($self, mName, pName, qName, &st);
    RAISE_IF(st);

    return result;
  }

  /* Get the namespace component. */
  const char *namespace() 
  {
    const char* result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetCharPtr(CMGetNameSpace($self, &st));

    return result;
  }

  /* Set/replace the namespace component. */
#if defined(SWIGRUBY)
  %rename("namespace=") set_namespace(const char *nm);
#endif
  void set_namespace(const char *nm) 
  {
    RAISE_IF(CMSetNameSpace($self, nm));
  }

  /* Set/replace the hostname component. */
#if defined(SWIGRUBY)
  %rename("hostname=") set_hostname(const char *hostname);
#endif
  void set_hostname(const char *hostname) 
  {
    RAISE_IF(CMSetHostname($self, hostname));
  }

  /* Get the hostname component. */
  const char *hostname() 
  {
    const char* result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetCharPtr(CMGetHostname($self, NULL));
    RAISE_IF(st);

    return result;
  }

  /* Set/replace the classname component. */
#if defined(SWIGRUBY)
  %rename("classname=") set_classname(const char *classname);
#endif
  void set_classname(const char *classname) 
  {
    RAISE_IF(CMSetClassName($self, classname));
  }

  /* Get the classname component. */
  const char *classname() 
  {
    const char* result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetCharPtr(CMGetClassName($self, &st));
    RAISE_IF(st);

    return result;
  }
}

#-----------------------------------------------------
#
# CMPIInstance
#

/*
 * Document-class: CMPIInstance
 *
 */
%extend _CMPIInstance 
{
#if HAVE_CMPI_BROKER
  CMPIInstance(CMPIObjectPath *path)
#else
  CMPIInstance(const CMPIBroker* broker, CMPIObjectPath *path)
#endif
  {
#if HAVE_CMPI_BROKER
    const CMPIBroker* broker = cmpi_broker();
#endif
    return CMNewInstance(broker, path, NULL);
  }

  /* path: ObjectPath containing namespace and classname. */
  ~CMPIInstance() 
  { 
  }

#if defined(SWIGRUBY)
  %alias set "[]=";
  /*
   * Property setting in Ruby
   * instance[:propname] = data    # set by name (symbol)
   * instance["propname"] = data   # set by name (string)
   */
  CMPIStatus set(VALUE property, VALUE data)
  {
    const char *name;
    CMPIValue *value = (CMPIValue *)malloc(sizeof(CMPIValue));
    CMPIType type;
    if (SYMBOL_P(property)) {
      name = rb_id2name(SYM2ID(property));
    }
    else {
      name = StringValuePtr(property);
    }
    switch (TYPE(data)) {
      case T_FLOAT:
        value->Float = RFLOAT(data)->value;
    type = CMPI_real32;
      break;
      case T_STRING:
        value->string = to_cmpi_string(data);
	type = CMPI_string;
      break; 
      case T_FIXNUM:
        value->Int = FIX2ULONG(data);
	type = CMPI_uint32;
      break;
      case T_TRUE:
        value->boolean = 1;
	type = CMPI_boolean;
      break;
      case T_FALSE:
        value->boolean = 0;
	type = CMPI_boolean;
      break;
      case T_SYMBOL:
        value->string = to_cmpi_string(data);
	type = CMPI_string;
      break;
      default:
        value->chars = NULL;
	type = CMPI_null;
        break;
    }
    return CMSetProperty($self, name, value, type);
  }
#endif

  /* Adds/replaces a named Property.
   * name: Entry name.
   * value: Address of value structure.
   * type: Value type.
   */
  void set_property(
      const char *name, 
      const CMPIValue * value, 
      const CMPIType type) 
  {
    RAISE_IF(CMSetProperty($self, name, value, type));
  }

#if defined(SWIGRUBY)
  %alias get "[]";
  /*
   * get a named property value
   * Property access in Ruby:
   * data = instance[:propname]     # access by name (symbol)
   * data = instance["propname"     # access by name (string)
   * data = instance[1]             # access by index
   */
  CMPIData get(VALUE property)
  {
    if (FIXNUM_P(property)) {
      return CMGetPropertyAt($self, FIX2ULONG(property), NULL, NULL);
    }
    else {
      const char *name;
      if (SYMBOL_P(property)) {
        name = rb_id2name(SYM2ID(property));
      }
      else {
        name = StringValuePtr(property);
      }
      return CMGetProperty($self, name, NULL);
    }
  }
#endif


#if defined(SWIGRUBY)
  %rename("property") get_property(const char *name);
#endif
  /* Get property by name */
  CMPIData get_property(const char *name) 
  {
    CMPIData result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetProperty($self, name, &st);
    RAISE_IF(st);

    return result;
  }

#if defined (SWIGRUBY)
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
#if defined (SWIGPERL)
  SV * 
#endif
  /** Gets a Property value defined by its index.
   * index: Position in the internal Data array.
   */
  __type get_property_at(int index) 
  {
    Target_Type tdata;
    Target_Type result;
    CMPIString *s = NULL;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data = CMGetPropertyAt($self, index, &s, &st);
    result = Target_Null;
    if (st.rc)
    {
        RAISE_IF(st);
        return result;
    }
/*    fprintf(stderr, "CMGetPropertyAt(%d) -> name %s, data type %x, state %x, value %p\n", index, CMGetCharPtr(s), data.type, data.state, data.value);
    fflush(stderr);
    */
    TARGET_THREAD_BEGIN_BLOCK;
    if (data.state == CMPI_goodValue || data.state == CMPI_keyValue)
       tdata = SWIG_NewPointerObj((void*) data_clone(&data), SWIGTYPE_p__CMPIData, 1);
    else if (data.state == CMPI_nullValue)
       tdata = Target_Null;
    else if (data.state == CMPI_notFound)
       tdata = Target_Null; /* FIXME: raise exception */
    else
       tdata = Target_Null; /* FIXME: raise exception */
#if defined (SWIGPYTHON)
    result = PyTuple_New(2);
    PyTuple_SetItem(result, 0, tdata);
    PyTuple_SetItem(result, 1, PyString_FromString(CMGetCharPtr(s)));
#else
    result = Target_SizedArray(2);
    Target_Append(result, tdata);
    Target_Append(result, Target_String(CMGetCharPtr(s)));
#endif
    TARGET_THREAD_END_BLOCK;
    return result;
  }

#if defined(SWIGRUBY)
  %alias property_count "size";
#endif
  /* Gets the number of properties contained in this Instance. */
  int property_count() 
  {
    int result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetPropertyCount($self, &st);
    RAISE_IF(st);

    return result;
  }

  /* Generates an ObjectPath out of the namespace, classname and
   *  key propeties of this Instance.
   */
  CMPIObjectPath *objectpath() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIObjectPath* result;

    result = CMGetObjectPath($self, &st);
    RAISE_IF(st);
    /* fprintf(stderr, "<%p>.objectpath = %p\n", $self, result); */

    return result;
  }

#if defined(SWIGRUBY)
  %alias set_objectpath "objectpath=";
#endif
  /* Replaces the ObjectPath of the instance.
   *  The passed objectpath shall contain the namespace, classname,
   *   as well as all keys for the specified instance.
   */
  void set_objectpath(const CMPIObjectPath *path) 
  {
    RAISE_IF(CMSetObjectPath($self, path));
  }

  /* Directs CMPI to ignore any setProperty operations for this
   *        instance for any properties not in this list.
   * properties: If not NULL, the members of the array define one
   *         or more Property names to be accepted by setProperty operations.
   */
  void set_property_filter(const char **properties) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIObjectPath* cop;
    CMPICount n;
    CMPICount i;
    CMPIData cd;
    char** props;

    /* Make copy of property list (we may modify it) */
    
    props = string_array_clone((char**)properties);

#if 0
    string_array_print(props);
#endif

    /* Pegasus requires that the keys be in the property list, else it
     * throws an exception. To work around, add key properties to property
     * list.
     */

    if (!(cop = CMGetObjectPath($self, &st)) || st.rc)
    {
        st.rc = CMPI_RC_ERR_FAILED;
        RAISE_IF(st);
        string_array_free(props);
        return;
    }

    n = CMGetKeyCount(cop, &st);

    if (st.rc)
    {
        RAISE_IF(st);
        string_array_free(props);
        return;
    }

    for (i = 0; i < n; i++)
    {
        CMPIString* pn = NULL;
        char* str;

        cd = CMGetKeyAt(cop, i, &pn, &st);

        if (st.rc)
        {
            RAISE_IF(st);
            string_array_free(props);
            return;
        }

        str = CMGetCharsPtr(pn, &st);

        if (st.rc)
        {
            RAISE_IF(st);
            string_array_free(props);
            return;
        }

        if (string_array_find_ignore_case(props, str) == NULL)
            props = string_array_append(props, str);
    }

#if 0
    string_array_print(props);
#endif

    RAISE_IF(CMSetPropertyFilter($self, (const char**)props, NULL));

    string_array_free(props);
  }

  /* Add/replace a named Property value and origin
   * name: is a string containing the Property name.
   * value: points to a CMPIValue structure containing the value
   *        to be assigned to the Property.
   * type: is a CMPIType structure defining the type of the value.
   * origin: specifies the instance origin.  If NULL, then
             no origin is attached to  the property
   */
  void set_property_with_origin(
      const char *name,
     const CMPIValue *value, 
     CMPIType type, 
     const char* origin)
  {
    RAISE_IF(CMSetPropertyWithOrigin($self, name, value, type, origin));
  }
}

#-----------------------------------------------------
#
# CMPIArgs

/*
 * CMPI Arguments
 *
 * Arguments are passed in an ordered Hash-like fashion (name/value pairs) and can
 * be accessed by name or by index
 *
 */
%extend _CMPIArgs 
{
  ~CMPIArgs() 
  { 
  }
  
  /*
   * Adds/replaces a named argument.
   *
   * call-seq:
   *   set("arg_name", arg_value, arg_type)
   *
   */
  void set(char *name, const CMPIValue * value, const CMPIType type) 
  {
    RAISE_IF(CMAddArg($self, name, value, type));
  }

#if defined(SWIGRUBY)
  %alias get "[]";
#endif
  /*
   * Gets a named argument value.
   *
   */
  CMPIData get(const char *name) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetArg($self, name, &st);
    RAISE_IF(st);

    return result;
  }

#if defined (SWIGRUBY)
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
#if defined (SWIGPERL)
  SV * 
#endif
  /*
   * Get an Argument value by index.
   * Returns a pair of value and name
   *
   * call-seq:
   *   get_arg_at(1) -> [ value, "name" ]
   *
   */
  __type get_arg_at(int index) 
  {
    Target_Type tdata;
    Target_Type result;
    CMPIString *s = NULL;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data = CMGetArgAt($self, index, &s, &st);

    result = Target_Null;
    if (st.rc)
    {
        RAISE_IF(st);
        return result;
    }
    TARGET_THREAD_BEGIN_BLOCK;
    tdata = SWIG_NewPointerObj((void*) data_clone(&data), SWIGTYPE_p__CMPIData, 1); 
#if defined (SWIGPYTHON)
    result = PyTuple_New(2);
    PyTuple_SetItem(result, 0, tdata);
    PyTuple_SetItem(result, 1, PyString_FromString(CMGetCharPtr(s)));
#else
    result = Target_SizedArray(2);
    Target_Append(result, tdata);
    Target_Append(result, Target_String(CMGetCharPtr(s)));
#endif
    TARGET_THREAD_END_BLOCK;
    return result;
  }

#if defined(SWIGRUBY)
  %alias get "size";
#endif
  /*
   * Gets the number of arguments contained in this Args.
   *
   */
  int arg_count() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    int result;

    result = CMGetArgCount($self, &st);
    RAISE_IF(st);

    return result;
  }
}

#-----------------------------------------------------
#
# CMPISelectExp

/*
 * This structure encompasses queries
 *       and provides mechanism to operate on the query.
 */
%extend _CMPISelectExp {
  ~CMPISelectExp() { }
  
  /* Return string representation */
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string() {
    return CMGetCharPtr(CMGetSelExpString($self, NULL));
  }
}

#-----------------------------------------------------
#
# CMPISelectCond

/*
 * Select conditions
 *
 *
 */
%extend _CMPISelectCond {
  /* Return string representation */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string() {
    const CMPIBroker* broker = cmpi_broker();
    CMPIString *s = CDToString(broker, $self, NULL);
    return CMGetCharPtr(s);
  }
#endif
}

#-----------------------------------------------------
#
# CMPISubCond

/*
 * Sub Conditions
 *
 *
 */
%extend _CMPISubCond {
}

#-----------------------------------------------------
#
# CMPIPredicate

/*
 * Predicate
 *
 *
 */
%extend _CMPIPredicate {
  /* Return string representation */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string() {
    const CMPIBroker* broker = cmpi_broker();
    CMPIString *s = CDToString(broker, $self, NULL);
    return CMGetCharPtr(s);
  }
#endif
}

#-----------------------------------------------------
#
# CMPIEnumeration

/*
 * Enumeration provide a linked-list type access to multiple elements
 *
 *
 */
%extend _CMPIEnumeration 
{
#if defined(SWIGRUBY)
  %alias length "size";
#endif
  int length() 
  {
    int l = 0;
    while (CMHasNext($self, NULL)) {
      ++l;
      CMGetNext($self, NULL);
    }
    return l;
  }
#if defined(SWIGPERL)
/* Warning(314): 'next' is a perl keyword */
%rename("_next") next;
#endif
  CMPIData next() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetNext($self, &st);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  %alias hasNext "empty?";
#endif
  int hasNext() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    int result;

    result = CMHasNext($self, NULL);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  %alias toArray "to_ary";
#endif
  CMPIArray *toArray() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIArray* result;

    result = CMToArray($self, NULL);
    RAISE_IF(st);

    return result;
  }

  /* Return string representation */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string()
  {
    const CMPIBroker* broker = cmpi_broker();
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIString *result;
    
    result = CDToString(broker, $self, &st);
    RAISE_IF(st);

    return CMGetCharPtr(result);
  }
#endif
}

#-----------------------------------------------------
#
# CMPIArray

/*
 * Array of equally-typed elements
 *
 *
 */
%extend _CMPIArray 
{
  /* Return string representation */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string()
  {
    const CMPIBroker* broker = cmpi_broker();
    CMPIString *s = CDToString(broker, $self, NULL);
    return CMGetCharPtr(s);
  }
#endif
  int size() 
  {
    return CMGetArrayCount($self, NULL);
  }

  /* Gets the element type.  */
  CMPIType cmpi_type() 
  {
    CMPIType result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetArrayType($self, &st);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  %alias at "[]";
#endif
  /* Gets an element value defined by its index. */
  CMPIData at(int index) 
  {
    CMPIData result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetArrayElementAt($self, index, &st);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  %alias set "[]=";
#endif
  /* Sets an element value defined by its index. */
  void set(int index, const CMPIValue * value, CMPIType type) 
  {
    RAISE_IF(CMSetArrayElementAt($self, index, value, type));
  }
}

#BOOKMARK

#-----------------------------------------------------
#
# CMPIString

/*
 * A string
 *
 */
%extend _CMPIString {
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string() {
    return CMGetCharPtr($self);
  }
}

#-----------------------------------------------------
#
# CMPIContext

/*
 * Context of the provider invocation
 *
 *
 */
%extend _CMPIContext {
  /*
   * Return string representation
   */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string() {
    const CMPIBroker* broker = cmpi_broker();
    CMPIString *s = CDToString(broker, $self, NULL);
    return CMGetCharPtr(s);
  }
#endif  
  /*
   * Add entry by name
   */
  void add_entry(const char* name, const CMPIValue* data, 
                     const CMPIType type) {
    CMAddContextEntry($self, name, data, type);
  }

  /*
   * Get entry by name
   */
  CMPIData get_entry(const char* name) {
    return CMGetContextEntry($self, name, NULL); // TODO CMPIStatus exception handling
  }

  /*
   * Get entry by index
   *
   * returns a name:string,value:CMPIData pair
   */
#if defined (SWIGRUBY)
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
#if defined (SWIGPERL)
  SV* 
#endif
  __type get_entry_at(int index) {
    Target_Type tdata;
    Target_Type result;
    CMPIString *s = NULL;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data = CMGetContextEntryAt($self, index, &s, &st);

    result = Target_Null;
    if (st.rc)
    {
        RAISE_IF(st);
        return result;
    }
    TARGET_THREAD_BEGIN_BLOCK;
    tdata = SWIG_NewPointerObj((void*) data_clone(&data), SWIGTYPE_p__CMPIData, 1); 
#if defined (SWIGPYTHON)
    result = PyTuple_New(2);
    PyTuple_SetItem(result, 0, PyString_FromString(CMGetCharPtr(s)));
    PyTuple_SetItem(result, 1, tdata);
#else
    result = Target_SizedArray(2);
    Target_Append(result, Target_String(CMGetCharPtr(s)));
    Target_Append(result, tdata);
#endif
    TARGET_THREAD_END_BLOCK;
    return result;
  }

  /*
   * Get number of entries in Context
   */
  CMPICount get_entry_count(void) {
     return CMGetContextEntryCount($self, NULL); 
    // TODO CMPIStatus exception handling
  }

}

#-----------------------------------------------------
#
# CMPIDateTime

/*
 * Date and Time
 *
 *
 */
%extend _CMPIDateTime {
  ~CMPIDateTime() { }
  
  /* Return string representation */
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string() {
    return CMGetCharPtr(CMGetStringFormat($self, NULL));
  }
  
  /* Return integer representation */
  uint64_t to_i() {
    return CMGetBinaryFormat($self, NULL);
  }
  
#if defined(SWIGRUBY)
  %rename("interval?") is_interval;
#endif
  /* Tests whether DateTime is an interval value. */
  int is_interval() {
    return CMIsInterval($self, NULL);
  }
}

# EOF

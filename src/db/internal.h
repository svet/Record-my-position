// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#define DB_ROW_TYPE_LOG			0
#define DB_ROW_TYPE_COORD		1
#define DB_ROW_TYPE_NOTE		2

#ifdef DEBUG
#define LOG_ERROR(RES,QUERY,DO_ASSERT) do {									\
	if (RES.errorCode) {													\
		if (QUERY)															\
			DLOG(@"DB error running %@.\n%@", QUERY, RES.errorMessage);		\
		else																\
			DLOG(@"DB error code %d.\n%@", RES.errorCode, RES.errorMessage);\
		NSAssert(!(DO_ASSERT), @"Database query error");					\
	}																		\
} while(0)
#else
#define LOG_ERROR(RES,QUERY,DO_ASSERT) do { } while(0)
#endif


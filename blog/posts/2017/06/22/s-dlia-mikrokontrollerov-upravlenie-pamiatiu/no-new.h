#include <stddef.h> // size_t
#include <cstddef>

// Overload global new/delete like «int *y = new int;»
// https://stackoverflow.com/a/18366272

inline void* operator new ( size_t sz ) {
    extern void *bare_new_erroneously_called();
    return bare_new_erroneously_called();
}

inline void* operator new[] ( size_t size ) {
    return new int; 
}

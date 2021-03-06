# distutils: language = c++
from libcpp.vector cimport vector
from libcpp.memory cimport unique_ptr
from libc.stdint cimport uint64_t, UINT64_MAX
from cython.operator cimport dereference as deref
import numpy as np

### wrap iostream stuff

# iostream stuff taken from:
#   https://stackoverflow.com/questions/30984078/cython-working-with-c-streams
cdef extern from "<iostream>" namespace "std":
    cdef cppclass ostream:
        ostream& write(const char*, int) except +

    cdef cppclass istream:
        istream& read(char *, int) except +

# obviously std::ios_base isn't a namespace, but this lets
# Cython generate the correct C++ code
cdef extern from "<iostream>" namespace "std::ios_base":
    cdef cppclass open_mode:
        pass
    cdef open_mode binary
    # you can define other constants as needed

cdef extern from "<fstream>" namespace "std":
    cdef cppclass ofstream(ostream):
        # constructors
        ofstream(const char*) except +
        ofstream(const char*, open_mode) except+

    cdef cppclass ifstream(istream):
        # constructors
        ifstream(const char*) except +
        ifstream(const char*, open_mode) except+

### Wrap the headers from BBhash

cdef extern from "BooPHF.h" namespace "boomphf":
    cdef cppclass SingleHashFunctor[T]:
        uint64_t operator ()

    cdef cppclass mphf[T,U]:
        mphf(unsigned long long, vector[T], int, float) except +
        uint64_t lookup(uint64_t)
        void save(ofstream)
        void load(ifstream)

### provide a Python wrapper.

ctypedef SingleHashFunctor[uint64_t] hasher_t
ctypedef mphf[uint64_t, hasher_t] mphf_t

cdef class PyMPHF:
    cdef unique_ptr[mphf_t] c_mphf

    def __cinit__(self, uint64_t [:] kk, unsigned long long nelem, int num_thread, float gamma):
        cdef vector[uint64_t] kmers
        N = kk.shape[0]
        for i in range(N):
            kmers.push_back(kk[i])
        self.c_mphf.reset(new mphf_t(nelem, kmers, num_thread, gamma))
        # self.c_mphf.reset(new mphf_t(nelem, kk, num_thread, gamma))

    def lookup(self, uint64_t kmer):
        cdef uint64_t value = deref(self.c_mphf).lookup(kmer)
        if value != UINT64_MAX:
            return value
        return None

    def save(self, str filename):
        cdef ofstream* outputter
        outputter = new ofstream(filename.encode(), binary)
        try:
            deref(self.c_mphf).save(deref(outputter))
        finally:
            del outputter

    def load(self, str filename):
        cdef ifstream* inputter
        inputter = new ifstream(filename.encode(), binary)
        try:
            deref(self.c_mphf).load(deref(inputter))
        finally:
            del inputter

def load_mphf(filename):
    m = PyMPHF(np.array([], dtype='uint64'), 0, 1, 1.0)
    m.load(filename)

    return m

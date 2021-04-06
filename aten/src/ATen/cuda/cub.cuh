#pragma once

#include <cstddef>

// include cub in a safe manner, see:
// https://github.com/pytorch/pytorch/pull/55292
#undef CUB_NS_POSTFIX //undef to avoid redefinition warnings
#undef CUB_NS_PREFIX
#define CUB_NS_PREFIX namespace at { namespace cuda { namespace detail {
#define CUB_NS_POSTFIX }}}
#include <cub/cub.cuh>
#undef CUB_NS_POSTFIX
#undef CUB_NS_PREFIX

namespace at { namespace native {

namespace cub = at::cuda::detail::cub;

}}

#include <ATen/cuda/Exceptions.h>
#include <c10/cuda/CUDACachingAllocator.h>

// handle the temporary storage and 'twice' calls for cub API
#define CUB_WRAPPER(func, ...) do {                                        \
  size_t temp_storage_bytes = 0;                                           \
  func(nullptr, temp_storage_bytes, __VA_ARGS__);                          \
  auto allocator = c10::cuda::CUDACachingAllocator::get();                 \
  auto temp_storage = allocator->allocate(temp_storage_bytes);             \                       \
  func(temp_storage.get(), temp_storage_bytes, __VA_ARGS__);               \
  AT_CUDA_CHECK(cudaGetLastError());                                       \
} while (false)

namespace at {
namespace cuda {
namespace cub {

template<typename T>
struct cuda_type {
  using type = T;
};
template<>
struct cuda_type<c10::Half> {
  using type = __half;
};

template<typename key_t, typename value_t>
static inline void sort_pairs(
    const key_t *keys_in, key_t *keys_out,
    const value_t *values_in, value_t *values_out,
    int64_t n, bool descending=false, int64_t start_bit=0, int64_t end_bit=sizeof(key_t)*8
) {
  using key_t_ = typename cuda_type<key_t>::type;
  using value_t_ = typename cuda_type<value_t>::type;
  const key_t_ *keys_in_ = reinterpret_cast<const key_t_*>(keys_in);
  key_t_ *keys_out_ = reinterpret_cast<key_t_*>(keys_out);
  const value_t_ *values_in_ = reinterpret_cast<const value_t_*>(values_in);
  value_t_ *values_out_ = reinterpret_cast<value_t_*>(values_out);

  // if (descending) {
  //   CUB_WRAPPER(at::native::cub::DeviceRadixSort::SortPairsDescending,
  //     keys_in_, keys_out_, values_in_, values_out_, n,
  //     start_bit, end_bit, at::cuda::getCurrentCUDAStream());
  // } else {
  //   CUB_WRAPPER(at::native::cub::DeviceRadixSort::SortPairs,
  //     keys_in_, keys_out_, values_in_, values_out_, n,
  //     start_bit, end_bit, at::cuda::getCurrentCUDAStream());
  // }
}

}}}

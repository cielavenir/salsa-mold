#include "mold.h"

#include <limits>

namespace mold::elf {

template <typename E>
bool CieRecord<E>::equals(const CieRecord<E> &other) const {
  if (get_contents() != other.get_contents())
    return false;

  std::span<ElfRel<E>> x = get_rels();
  std::span<ElfRel<E>> y = other.get_rels();
  if (x.size() != y.size())
    return false;

  for (i64 i = 0; i < x.size(); i++) {
    if (x[i].r_offset - input_offset != y[i].r_offset - other.input_offset ||
        x[i].r_type != y[i].r_type ||
        file.symbols[x[i].r_sym] != other.file.symbols[y[i].r_sym] ||
        input_section.get_addend(x[i]) != other.input_section.get_addend(y[i]))
      return false;
  }
  return true;
}

template <typename E>
InputSection<E>::InputSection(Context<E> &ctx, ObjectFile<E> &file,
                              const ElfShdr<E> &shdr, std::string_view name,
                              std::string_view contents, i64 section_idx)
  : file(file), shdr(shdr), contents(contents), nameptr(name.data()),
    namelen(name.size()), section_idx(section_idx) {
  output_section =
    OutputSection<E>::get_instance(ctx, name, shdr.sh_type, shdr.sh_flags);
}

template <typename E>
void InputSection<E>::write_to(Context<E> &ctx, u8 *buf) {
  if (shdr.sh_type == SHT_NOBITS || shdr.sh_size == 0)
    return;

  // Copy data
  memcpy(buf, contents.data(), contents.size());

  // Apply relocations
  if (shdr.sh_flags & SHF_ALLOC)
    apply_reloc_alloc(ctx, buf);
  else
    apply_reloc_nonalloc(ctx, buf);
}

template <typename E>
static i64 get_output_type(Context<E> &ctx) {
  if (ctx.arg.shared)
    return 0;
  if (ctx.arg.pie)
    return 1;
  return 2;
}

template <typename E>
static i64 get_sym_type(Symbol<E> &sym) {
  if (sym.is_absolute())
    return 0;
  if (!sym.is_imported)
    return 1;
  if (sym.get_type() != STT_FUNC)
    return 2;
  return 3;
}

template <typename E>
void InputSection<E>::dispatch(Context<E> &ctx, Action table[3][4], i64 i,
                               const ElfRel<E> &rel, Symbol<E> &sym) {
  Action action = table[get_output_type(ctx)][get_sym_type(sym)];
  bool is_code = (shdr.sh_flags & SHF_EXECINSTR);
  bool is_writable = (shdr.sh_flags & SHF_WRITE);

  auto error = [&]() {
    Error(ctx) << *this << ": " << rel << " relocation against symbol `"
               << sym << "' can not be used; recompile with -fPIC";
  };

  switch (action) {
  case NONE:
    return;
  case ERROR:
    error();
    return;
  case COPYREL:
    if (!ctx.arg.z_copyreloc) {
      error();
      return;
    }

    if (sym.esym().st_visibility == STV_PROTECTED) {
      Error(ctx) << *this
                 << ": cannot make copy relocation for protected symbol '"
                 << sym << "', defined in " << *sym.file
                 << "; recompile with -fPIC";
      return;
    }

    sym.flags |= NEEDS_COPYREL;
    return;
  case PLT:
    sym.flags |= NEEDS_PLT;
    return;
  case DYNREL:
    if (!is_writable) {
      if (!is_code || ctx.arg.z_text) {
        error();
        return;
      }
      ctx.has_textrel = true;
    }

    assert(sym.is_imported);
    needs_dynrel[i] = true;
    file.num_dynrel++;
    return;
  case BASEREL:
    if (!is_writable) {
      if (!is_code || ctx.arg.z_text) {
        error();
        return;
      }
      ctx.has_textrel = true;
    }

    needs_baserel[i] = true;
    if (!is_relr_reloc(ctx, rel))
      file.num_dynrel++;
    return;
  default:
    unreachable();
  }
}

template <typename E>
void InputSection<E>::report_undef(Context<E> &ctx, Symbol<E> &sym) {
  switch (ctx.arg.unresolved_symbols) {
  case UNRESOLVED_ERROR:
    Error(ctx) << "undefined symbol: " << file << ": " << sym;
    break;
  case UNRESOLVED_WARN:
    Warn(ctx) << "undefined symbol: " << file << ": " << sym;
    break;
  case UNRESOLVED_IGNORE:
    break;
  }
}

#define INSTANTIATE(E)                          \
  template struct CieRecord<E>;                 \
  template class InputSection<E>;

INSTANTIATE(X86_64);
INSTANTIATE(I386);
INSTANTIATE(ARM64);

} // namespace mold::elf

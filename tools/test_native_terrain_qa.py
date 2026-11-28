from pathlib import Path
from tempfile import TemporaryDirectory
import hashlib,sys
sys.path.insert(0,str(Path(__file__).parent))
from qa_native_terrain import apply,restore,paths,sha,spatial_off
def expect_error(fn):
    try: fn()
    except (RuntimeError,FileNotFoundError): return
    raise AssertionError("expected refusal")
with TemporaryDirectory() as tmp:
    game=Path(tmp);b=game/"bin64";b.mkdir()
    dll,disabled,ini,j=paths(game)
    data=b"test dll";dll.write_bytes(data);known=hashlib.sha256(data).hexdigest()
    original=b"[FPS]\r\ntarget_fps=240\r\n[OPTIMIZE]\r\nfast_spatial_query=1\r\nfast_libdeflate_zip=0\r\n"
    ini.write_bytes(original)
    expect_error(lambda:apply(game,"spatial-off"))
    apply(game,"spatial-off",known)
    assert dll.read_bytes()==data and ini.read_bytes()==original.replace(b"query=1",b"query=0")
    expect_error(lambda:apply(game,"vanilla",known))
    changed=ini.read_bytes();ini.write_bytes(changed+b"\r\n")
    expect_error(lambda:restore(game));ini.write_bytes(changed)
    restore(game);assert ini.read_bytes()==original and not j.exists()
    apply(game,"vanilla",known);assert not dll.exists() and disabled.read_bytes()==data
    restore(game);assert dll.read_bytes()==data and not disabled.exists() and ini.read_bytes()==original
    expect_error(lambda:spatial_off(b"fast_spatial_query=0"))
    expect_error(lambda:spatial_off(b"fast_spatial_query=1\nfast_spatial_query=1\n"))
print("PASS native QA profiles: known hash, exact INI change, no overwrite, conflict refusal, vanilla and byte-for-byte restore")

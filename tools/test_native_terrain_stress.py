"""Repeat native profile transactions on COPIES of installed DLL/INI."""
from pathlib import Path
from tempfile import TemporaryDirectory
from contextlib import redirect_stdout
import io, shutil
from qa_native_terrain import DEFAULT, KNOWN, apply, restore, paths, sha
def main():
    origdll,_,origini,_=paths(DEFAULT)
    before=sha(origini)
    assert sha(origdll)==KNOWN
    with TemporaryDirectory(prefix="qps-native-stress-") as td:
        game=Path(td); (game/"bin64").mkdir()
        dll,disabled,ini,j=paths(game)
        shutil.copyfile(origdll,dll);shutil.copyfile(origini,ini)
        for i in range(150):
            mode=("spatial-off","texture-off","vanilla")[i%3]
            with redirect_stdout(io.StringIO()):
                apply(game,mode)
                if mode=="vanilla":
                    assert not dll.exists() and sha(disabled)==KNOWN
                else:
                    assert sha(dll)==KNOWN and ini.read_bytes()!=origini.read_bytes()
                restore(game)
            assert not j.exists() and not disabled.exists()
            assert sha(dll)==KNOWN and sha(ini)==before
    assert sha(origdll)==KNOWN and sha(origini)==before
    print("PASS 150 native profile transactions on actual byte copies: 50 spatial-off, 50 texture-off, 50 vanilla, 150 exact restores; live files unchanged.")
if __name__=="__main__":
    main()

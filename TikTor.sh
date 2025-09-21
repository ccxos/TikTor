#Thx!
set -e

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python3 not found. Please install python3 and try again."
  exit 1
fi

INSTALL_DIR="$PWD"
cd "$INSTALL_DIR" || exit 1

echo "Checking required python modules..."
python3 -c 'import importlib,subprocess,sys
pkgs=["requests","pycountry"]
for p in pkgs:
    try:
        importlib.import_module(p)
    except ImportError:
        subprocess.check_call([sys.executable,"-m","pip","install",p])
' || { echo "Failed installing python packages (you can manually run: python3 -m pip install requests pycountry)"; }

PYFILE=$(mktemp /tmp/TikTor.XXXXXX.py) || PYFILE="$INSTALL_DIR/TikTor_embedded.py"

cat > "$PYFILE" <<'PYCODE'
import requests
import os
import sys
import time
import webbrowser
import pycountry
import re

CYAN = "\033[1;36m"
GREEN = "\033[1;32m"
DARK_RED = "\033[0;31m"
MAGENTA = "\033[1;35m"
YELLOW = "\033[1;33m"
RESET = "\033[0m"

BASE_DIR = os.environ.get("TIKTOR_DIR") or (
    "/storage/emulated/0/TikTor"
    if os.path.exists("/storage/emulated/0")
    else os.path.join(os.path.expanduser("~"), "TikTor")
)

VIDEOS_DIR = os.path.join(BASE_DIR, "Videos")
IMAGES_DIR = os.path.join(BASE_DIR, "Images")
INFOS_DIR = os.path.join(BASE_DIR, "Informations")

SIMPSON_ART = r"""
 _________   ___   ___  __     _________   ________   ________     
|\___   ___\|\  \ |\  \|\  \  |\___   ___\|\   __  \ |\   __  \    
\|___ \  \_|\ \  \\ \  \/  /|_\|___ \  \_|\ \  \|\  \\ \  \|\  \   
     \ \  \  \ \  \\ \   ___  \    \ \  \  \ \  \\\  \\ \   _  _\  
      \ \  \  \ \  \\ \  \\ \  \    \ \  \  \ \  \\\  \\ \  \\  \| 
       \ \__\  \ \__\\ \__\\ \__\    \ \__\  \ \_______\\ \__\\ _\ 
        \|__|   \|__| \|__| \|__|     \|__|   \|_______| \|__|\|__|
"""

DARK_MESSAGE = "masturbation is necrophilia if you're dead inside"

TYPING_CHAR_DELAY = 0.06
PAUSE_AFTER_TYPING = 2.0
PAUSE_AFTER_CLEAR = 1.0
ASCII_DISPLAY_PAUSE = 0
WELCOME_PAUSE = 0
PAUSE_BEFORE_EXIT = 1.0

def clear_screen_and_scrollback():
    try:
        sys.stdout.write("\033[3J\033[H\033[2J")
        sys.stdout.flush()
    except Exception:
        pass
    os.system("cls" if os.name == "nt" else "clear")

def typing_print(text, color=DARK_RED, char_delay=TYPING_CHAR_DELAY):
    sys.stdout.write(color)
    sys.stdout.flush()
    for ch in text:
        sys.stdout.write(ch)
        sys.stdout.flush()
        time.sleep(char_delay)
    sys.stdout.write(RESET + "\n")
    sys.stdout.flush()

def ensure_dirs():
    os.makedirs(VIDEOS_DIR, exist_ok=True)
    os.makedirs(IMAGES_DIR, exist_ok=True)
    os.makedirs(INFOS_DIR, exist_ok=True)

def sanitize_filename(name):
    name = str(name)
    name = name.strip()
    name = re.sub(r'[\\/:\*\?"<>\|]+', '_', name)
    return name

def fetch_tikwm_api(link):
    url = f"https://www.tikwm.com/api/?url={link}"
    r = requests.get(url, timeout=15)
    r.raise_for_status()
    return r.json()

def download_file_from_url(url, out_path):
    resp = requests.get(url, stream=True, timeout=30)
    resp.raise_for_status()
    with open(out_path, "wb") as f:
        for chunk in resp.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)

def extract_image_urls(data):
    urls = []
    if isinstance(data, dict) and "images" in data and isinstance(data["images"], list):
        urls.extend(data["images"])
    return [u for u in urls if u]

def get_user_info(username):
    headers = {
        "Host": "www.tiktok.com",
        "sec-ch-ua": "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"99\", \"Google Chrome\";v=\"99\"",
        "sec-ch-ua-mobile": "?1",
        "sec-ch-ua-platform": "\"Android\"",
        "upgrade-insecure-requests": "1",
        "user-agent": "Mozilla/5.0 (Linux; Android 8.0.0; Plume L2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.88 Mobile Safari/537.36",
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "sec-fetch-site": "none",
        "sec-fetch-mode": "navigate",
        "sec-fetch-user": "?1",
        "sec-fetch-dest": "document",
        "accept-language": "en-US,en;q=0.9"
    }
    response = requests.get(f'https://www.tiktok.com/@{username}', headers=headers, timeout=15)
    response.raise_for_status()
    raw = response.text
    if 'webapp.user-detail"' not in raw:
        raise KeyError
    raw_data = raw.split('webapp.user-detail"')[1].split('"RecommendUserList"')[0]
    user_id = raw_data.split('id":"')[1].split('",')[0] if 'id":"' in raw_data else "N/A"
    name = raw_data.split('nickname":"')[1].split('",')[0] if 'nickname":"' in raw_data else "N/A"
    bio = raw_data.split('signature":"')[1].split('",')[0] if 'signature":"' in raw_data else "N/A"
    country_code = raw_data.split('region":"')[1].split('",')[0] if 'region":"' in raw_data else ""
    private = raw_data.split('privateAccount":')[1].split(',"')[0] if 'privateAccount":' in raw_data else "N/A"
    followers = raw_data.split('followerCount":')[1].split(',"')[0] if 'followerCount":' in raw_data else "N/A"
    following = raw_data.split('followingCount":')[1].split(',"')[0] if 'followingCount":' in raw_data else "N/A"
    likes = raw_data.split('heart":')[1].split(',"')[0] if 'heart":' in raw_data else "N/A"
    videos = raw_data.split('videoCount":')[1].split(',"')[0] if 'videoCount":' in raw_data else "N/A"
    secid = raw_data.split('secUid":"')[1].split('"')[0] if 'secUid":"' in raw_data else "N/A"
    country_name = "N/A"
    if country_code:
        try:
            country = pycountry.countries.get(alpha_2=country_code)
            if country:
                country_name = country.name
        except Exception:
            pass
    info = {
        "username": username,
        "secid": secid,
        "name": name,
        "followers": followers,
        "following": following,
        "likes": likes,
        "videos": videos,
        "private": private,
        "country": country_name,
        "user_id": user_id,
        "bio": bio
    }
    return info

def print_user_info(info):
    print(YELLOW + f"• Username ➜ {info['username']}" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• SecUid ➜ `{info['secid']}`" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• Name ➜ {info['name']}" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• Followers ➜ {info['followers']}" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• Following ➜ {info['following']}" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• Likes ➜ {info['likes']}" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• Videos ➜ {info['videos']}" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• Private Account ? ➜ {info['private']}" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• Country ➜ {info['country']}" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• User ID ➜ `{info['user_id']}`" + RESET)
    print()
    time.sleep(0.25)
    print(YELLOW + f"• Bio ➜ {info['bio']}" + RESET)
    print()
    time.sleep(0.5)

def save_info_to_file(info):
    filename = f"{info['username']}.txt"
    filename = sanitize_filename(filename)
    path = os.path.join(INFOS_DIR, filename)
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"Username ➜ {info['username']}\n\n")
        f.write(f"SecUid ➜ {info['secid']}\n\n")
        f.write(f"Name ➜ {info['name']}\n\n")
        f.write(f"Followers ➜ {info['followers']}\n\n")
        f.write(f"Following ➜ {info['following']}\n\n")
        f.write(f"Likes ➜ {info['likes']}\n\n")
        f.write(f"Videos ➜ {info['videos']}\n\n")
        f.write(f"Private Account ? ➜ {info['private']}\n\n")
        f.write(f"Country ➜ {info['country']}\n\n")
        f.write(f"User ID ➜ {info['user_id']}\n\n")
        f.write(f"Bio ➜ {info['bio']}\n\n")
    return path

def full_start_sequence():
    ensure_dirs()
    clear_screen_and_scrollback()
    typing_print(DARK_MESSAGE, color=DARK_RED, char_delay=TYPING_CHAR_DELAY)
    time.sleep(PAUSE_AFTER_TYPING)
    clear_screen_and_scrollback()
    time.sleep(PAUSE_AFTER_CLEAR)
    print(MAGENTA + SIMPSON_ART + RESET)
    print()
    time.sleep(ASCII_DISPLAY_PAUSE)
    print(DARK_RED + f"If u had a Problem , Text Me In Telegram : {GREEN} @binst" + RESET)
    print()
    time.sleep(WELCOME_PAUSE)

def main():
    while True:
        full_start_sequence()
        while True:
            print(CYAN + "[1] ~ Download TikTok video" + RESET)
            print()
            time.sleep(0.08)
            print(CYAN + "[2] ~ Download TikTok image(s)" + RESET)
            print()
            time.sleep(0.08)
            print(CYAN + "[3] ~ Show TikTok user information" + RESET)
            print()
            time.sleep(0.08)
            print(DARK_RED + "[00] ~ Exit" + RESET)
            print()
            time.sleep(0.12)
            choice = input(CYAN + "Choose an option : " + RESET).strip()
            print()
            time.sleep(0.12)
            if choice == "00":
                print()
                sys.stdout.write("\033[3J\033[H\033[2J")
                sys.stdout.flush()
                time.sleep(0.0)
                os._exit(0)
            if choice == "1":
                while True:
                    try:
                        link = input(CYAN + "Put Your Link From TikTok : " + RESET).strip()
                        print()
                        time.sleep(0.12)
                        name = input(CYAN + "Write Video Name : " + RESET).strip()
                        print()
                        time.sleep(0)
                        api = fetch_tikwm_api(link)
                        pl = api['data']['play']
                        safe_name = sanitize_filename(name + ".mp4")
                        filename = os.path.join(VIDEOS_DIR, safe_name)
                        download_file_from_url(pl, filename)
                        print(GREEN + "----------- Done -----------" + RESET)
                        print()
                        time.sleep(2.1)
                        sys.stdout.write("\033[3J\033[H\033[2J")
                        sys.stdout.flush()
                        time.sleep(2)
                        break
                    except KeyError:
                        print(DARK_RED + "⚠️ Invalid link or data not found." + RESET)
                        print()
                        time.sleep(0.4)
                        continue
                    except requests.exceptions.RequestException:
                        print(DARK_RED + "❌ Connection error or invalid link. Try again." + RESET)
                        print()
                        time.sleep(0.6)
                        continue
                break
            elif choice == "2":
                while True:
                    try:
                        link = input(CYAN + "Put Your Link From TikTok : " + RESET).strip()
                        print()
                        time.sleep(0.5)
                        api = fetch_tikwm_api(link)
                        images = extract_image_urls(api.get("data", {}))
                        if not images:
                            print(DARK_RED + "No images found at this link." + RESET)
                            print()
                            time.sleep(0.5)
                            continue
                        for idx, img in enumerate(images):
                            try:
                                fname = os.path.basename(img.split("?")[0])
                            except Exception:
                                fname = ""
                            if not fname or '.' not in fname:
                                fname = f"image_{idx}_{int(time.time())}.jpg"
                            fname = sanitize_filename(fname)
                            fname = os.path.join(IMAGES_DIR, fname)
                            download_file_from_url(img, fname)
                            print(GREEN + f"Downloaded : {fname}" + RESET)
                            print()
                            time.sleep(0)
                        print(GREEN + "----------- Done -----------" + RESET)
                        print()
                        time.sleep(2.1)
                        sys.stdout.write("\033[3J\033[H\033[2J")
                        sys.stdout.flush()
                        time.sleep(2)
                        break
                    except KeyError:
                        print(DARK_RED + "⚠️ Invalid link or data not found. Please try again." + RESET)
                        print()
                        time.sleep(0.4)
                        continue
                    except requests.exceptions.RequestException:
                        print(DARK_RED + "❌ Connection error or invalid link." + RESET)
                        print()
                        time.sleep(0.6)
                        continue
                break
            elif choice == "3":
                while True:
                    try:
                        username = input(CYAN + "Put Username (without @) : " + RESET).strip().lstrip("@")
                        print()
                        time.sleep(0.12)
                        if not re.match("^[A-Za-z0-9_.]+$", username):
                            print(DARK_RED + "⚠️ Please send the username in English and without @" + RESET)
                            print()
                            time.sleep(0.4)
                            continue
                        info = get_user_info(username)
                        print_user_info(info)
                        while True:
                            print()
                            print(DARK_RED + "--------- Choose an option ---------" + RESET)
                            print()
                            time.sleep(0.3)
                            print(DARK_RED + "[1] ~ Save Information to a txt file" + RESET)
                            print()
                            time.sleep(0.08)
                            print(DARK_RED + "[00] ~ Exit" + RESET)
                            print()
                            time.sleep(0.08)
                            print(DARK_RED + "[11] ~ Restart" + RESET)
                            print()
                            time.sleep(0.12)
                            sub = input(DARK_RED + ": " + RESET).strip()
                            print()
                            time.sleep(0.5)
                            if sub == "1":
                                fname = save_info_to_file(info)
                                print(GREEN + f"Saved Information to {fname}" + RESET)
                                print()
                                time.sleep(0.6)
                                while True:
                                    print()
                                    print(DARK_RED + "--------- Choose an option ---------" + RESET)
                                    print()
                                    time.sleep(0.3)
                                    print(DARK_RED + "[00] ~ Exit" + RESET)
                                    print()
                                    time.sleep(0.08)
                                    print(DARK_RED + "[11] ~ Restart" + RESET)
                                    print()
                                    time.sleep(0.12)
                                    sub2 = input(DARK_RED + ": " + RESET).strip()
                                    print()
                                    time.sleep(0.12)
                                    if sub2 == "00":
                                        print()
                                        sys.stdout.write("\033[3J\033[H\033[2J")
                                        sys.stdout.flush()
                                        time.sleep(0.0)
                                        os._exit(0)
                                    elif sub2 == "11":
                                        print()
                                        sys.stdout.write("\033[3J\033[H\033[2J")
                                        sys.stdout.flush()
                                        time.sleep(2)
                                        raise RuntimeError("restart_tool")
                                    else:
                                        print(DARK_RED + "---- Invalid option ----" + RESET)
                                        print()
                                        time.sleep(0.4)
                                        continue
                            elif sub == "00":
                                print()
                                sys.stdout.write("\033[3J\033[H\033[2J")
                                sys.stdout.flush()
                                time.sleep(0.0)
                                os._exit(0)
                            elif sub == "11":
                                print()
                                sys.stdout.write("\033[3J\033[H\033[2J")
                                sys.stdout.flush()
                                time.sleep(2)
                                raise RuntimeError("restart_tool")
                            else:
                                print(DARK_RED + "---- Invalid option ----" + RESET)
                                print()
                                time.sleep(0.4)
                                continue
                    except KeyError:
                        print(DARK_RED + "⚠️ Invalid username or data not found." + RESET)
                        print()
                        time.sleep(0.4)
                        break
                    except requests.exceptions.RequestException:
                        print(DARK_RED + "❌ Connection error or invalid username." + RESET)
                        print()
                        time.sleep(0.6)
                        break
                    except RuntimeError:
                        break
                break
            else:
                print(DARK_RED + "---- Invalid choice ----" + RESET)
                print()
                time.sleep(0.4)
                continue

if __name__ == "__main__":
    try:
        main()
    except RuntimeError:
        main()
PYCODE

python3 "$PYFILE" "$@"
EXIT_CODE=$?

rm -f "$PYFILE"

exit $EXIT_CODE
import requests
from bs4 import BeautifulSoup as bs
import re
import time
from random import uniform
from tqdm import trange
import sqlite3

url = "https://kolesa.kz/cars/region-zapadnokazakshstabskaya-oblast/?auto-car-order=1"

USER_AGENT = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
}

def check_db_exists(con):
    cursor = con.cursor()
    query = """SELECT name FROM sqlite_master WHERE type='table' AND name='cars';"""
    with con:
        cursor.execute(query)
        if cursor.fetchone():
            return
    query = """
            CREATE TABLE IF NOT EXISTS cars
            (
                id          INTEGER NOT NULL PRIMARY KEY,
                url         TEXT    NOT NULL,
                title       TEXT,
                city     TEXT,
                description TEXT,
                price    INTEGER             NOT NULL
            );
            """
    with con:
        con.executescript(query)

def insert_flats_data_db(flats_data):
    con = sqlite3.connect('db.db')
    insert_flats_query = """
        INSERT OR IGNORE
        INTO cars(url, title, city, description, price)
        VALUES (?, ?, ?, ?, ?);
        """
    flats_value = [(flat.get('url'),flat.get('title'),flat.get('city'),flat.get('description'), flat.get('price'))for flat in flats_data]
    with con:
        con.executemany(insert_flats_query, flats_value)
        
def get_response(url):
    for delay in (15, 60, 300, 1200, 3600):
        try:
            response = requests.get(url, headers=USER_AGENT,timeout=20)
            if response.status_code == requests.codes.ok:
                return response
        except requests.RequestException as error:
            print(error)
        time.sleep(delay)

def cars():
    response = get_response(url)
    content = bs(response.text, "html.parser")
    subtitle = content.find("span", class_="js__search-form-submit-value")
    ads_count = int("".join(re.findall(r"\d+", subtitle.text.strip())))
    page_count = int(ads_count/20)
    next_btn = content.find("a", class_="right-arrow next_page")
    next_btn_url = next_btn.get("href").rsplit('=', 1)[0]+'='

    for num in trange(1, page_count + 1):
        ads_section = content.find("div", class_="a-list")
        ads_on_page = ads_section.find_all("div", attrs={"data-id": True})
        ads = [] 
        for ad in ads_on_page:
            ads_dict = {}
            title = ad.find_all("a", class_="a-card__link")[-1]
            ad_url = title.get("href")
            ads_dict['url'] = "https://kolesa.kz" + ad_url
            ads_dict['title'] = title.text.strip()
            ads_dict['price'] = int("".join(re.findall(r"\d+", ad.find("span", class_="a-card__price").text.strip())))
            ads_dict['description'] = ad.find("p", class_="a-card__description").text.strip()
            ads_dict['city'] = ad.find("span", {"data-test": "region"}).text.strip()
            ads.append(ads_dict)
        insert_flats_data_db(ads)
        if num < page_count:
            next_url = "https://kolesa.kz" + next_btn_url + str(num+1)
            response = get_response(next_url)
            content = bs(response.text, "html.parser")


if __name__ == '__main__':
    con = sqlite3.connect('db.db')
    check_db_exists(con)
    cars()
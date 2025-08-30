#!/bin/bash

# Kullanım kontrolü
if [[ $# -ne 2 ]]; then
    echo "Kullanım: $0 <dizin1> <dizin2>"
    echo "Örnek: $0 /path/to/dir1 /path/to/dir2"
    exit 1
fi

DIR1="$1"
DIR2="$2"

# Dizinlerin varlığını kontrol et
if [[ ! -d "$DIR1" ]]; then
    echo "❌ Hata: $DIR1 dizini bulunamadı!"
    exit 1
fi

if [[ ! -d "$DIR2" ]]; then
    echo "❌ Hata: $DIR2 dizini bulunamadı!"
    exit 1
fi

echo "📁 Karşılaştırma: $(basename "$DIR1") ↔ $(basename "$DIR2")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Alt dizinlerin gerçek aralığını tespit et
ALL_SUBDIRS=$(find "$DIR1" "$DIR2" -maxdepth 1 -type d -name "[0-9][0-9][0-9]" 2>/dev/null | xargs -I {} basename {} | sort -n | uniq)

if [[ -z "$ALL_SUBDIRS" ]]; then
    echo "❌ Hiç alt dizin bulunamadı!"
    exit 1
fi

MIN_DIR=$(echo "$ALL_SUBDIRS" | head -1)
MAX_DIR=$(echo "$ALL_SUBDIRS" | tail -1)
TOTAL_SUBDIRS=$(echo "$ALL_SUBDIRS" | wc -l)
echo "📊 Alt dizin aralığı: $MIN_DIR - $MAX_DIR (Toplam: $TOTAL_SUBDIRS dizin)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Tespit edilen alt dizinler için karşılaştırma yap
PROCESSED=0
MISSING_FOUND=0
for i in $ALL_SUBDIRS; do
    PROCESSED=$((PROCESSED + 1))
    SUBDIR1="$DIR1/$i"
    SUBDIR2="$DIR2/$i"
    
    # Alt dizinlerin varlığını kontrol et
    if [[ ! -d "$SUBDIR1" ]] && [[ ! -d "$SUBDIR2" ]]; then
        continue  # Her iki dizin de yoksa hiçbir şey gösterme
    elif [[ ! -d "$SUBDIR1" ]]; then
        DIR2_COUNT=$(find "$SUBDIR2" -type f 2>/dev/null | wc -l)
        if [[ $DIR2_COUNT -gt 0 ]]; then
            DIR2_PREFIXES=$(find "$SUBDIR2" -type f 2>/dev/null | xargs -I {} basename {} 2>/dev/null | cut -c1-4 | tr '[:upper:]' '[:lower:]' | sort | uniq | tr '\n' ',' | sed 's/,$//')
            printf "📂 %s: DIR1=❌ DIR2=%d ➤ DIR1'de eksik: %s\n" "$i" "$DIR2_COUNT" "$DIR2_PREFIXES"
            MISSING_FOUND=$((MISSING_FOUND + 1))
        fi
        continue
    elif [[ ! -d "$SUBDIR2" ]]; then
        DIR1_COUNT=$(find "$SUBDIR1" -type f 2>/dev/null | wc -l)
        if [[ $DIR1_COUNT -gt 0 ]]; then
            DIR1_PREFIXES=$(find "$SUBDIR1" -type f 2>/dev/null | xargs -I {} basename {} 2>/dev/null | cut -c1-4 | tr '[:upper:]' '[:lower:]' | sort | uniq | tr '\n' ',' | sed 's/,$//')
            printf "📂 %s: DIR1=%d DIR2=❌ ➤ DIR2'de eksik: %s\n" "$i" "$DIR1_COUNT" "$DIR1_PREFIXES"
            MISSING_FOUND=$((MISSING_FOUND + 1))
        fi
        continue
    fi
    
    # Geçici dosyalar oluştur
    TEMP1=$(mktemp)
    TEMP2=$(mktemp)
    
    # Prefix'leri topla
    find "$SUBDIR1" -type f 2>/dev/null | xargs -I {} basename {} 2>/dev/null | cut -c1-4 | tr '[:upper:]' '[:lower:]' | sort | uniq > "$TEMP1"
    find "$SUBDIR2" -type f 2>/dev/null | xargs -I {} basename {} 2>/dev/null | cut -c1-4 | tr '[:upper:]' '[:lower:]' | sort | uniq > "$TEMP2"
    
    # Sayıları hesapla
    DIR1_COUNT=$(wc -l < "$TEMP1")
    DIR2_COUNT=$(wc -l < "$TEMP2")
    COMMON_COUNT=$(comm -12 "$TEMP1" "$TEMP2" | wc -l)
    
    # Eksik olanları bul
    MISSING_IN_DIR2=$(comm -23 "$TEMP1" "$TEMP2" | tr '\n' ',' | sed 's/,$//')
    MISSING_IN_DIR1=$(comm -13 "$TEMP1" "$TEMP2" | tr '\n' ',' | sed 's/,$//')
    
    # Sadece eksik dosya varsa göster
    if [[ -n "$MISSING_IN_DIR2" ]] || [[ -n "$MISSING_IN_DIR1" ]]; then
        printf "📂 %s: DIR1=%d DIR2=%d Ortak=%d" "$i" "$DIR1_COUNT" "$DIR2_COUNT" "$COMMON_COUNT"
        
        if [[ -n "$MISSING_IN_DIR2" ]] && [[ -n "$MISSING_IN_DIR1" ]]; then
            printf " ➤ DIR2'de eksik: %s | DIR1'de eksik: %s\n" "$MISSING_IN_DIR2" "$MISSING_IN_DIR1"
        elif [[ -n "$MISSING_IN_DIR2" ]]; then
            printf " ➤ DIR2'de eksik: %s\n" "$MISSING_IN_DIR2"
        elif [[ -n "$MISSING_IN_DIR1" ]]; then
            printf " ➤ DIR1'de eksik: %s\n" "$MISSING_IN_DIR1"
        fi
        MISSING_FOUND=$((MISSING_FOUND + 1))
    fi
    
    # Geçici dosyaları temizle
    rm -f "$TEMP1" "$TEMP2"
    
    # Script kesintiye uğramaması için hata kontrolü
    if [[ $? -ne 0 ]]; then
        echo "⚠️  Hata: $i dizininde sorun oluştu, devam ediliyor..."
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $MISSING_FOUND -eq 0 ]]; then
    echo "✅ Tüm dizinler eşleşiyor! ($PROCESSED dizin kontrol edildi)"
else
    echo "✅ Karşılaştırma tamamlandı! ($PROCESSED dizin kontrol edildi, $MISSING_FOUND dizinde eksik dosya bulundu)"
fi

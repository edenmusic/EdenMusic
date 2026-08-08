

    // Activate visualizer wave animation when the player state switches to 'play'
    player.addEventListener('play', () => {
        visualizer.classList.add('playing');
    });

    // Halt active animations when audio stream is suspended or stopped
    player.addEventListener('pause', () => {
        visualizer.classList.remove('playing');
    });
});

// 1. App Router Controller Mechanics
function switchTab(tabName) {
    document.querySelectorAll('.tab-view').forEach(view => view.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(btn => btn.classList.remove('active'));
    document.getElementById(`${tabName}-view`).classList.add('active');
    
    const navButtons = document.querySelectorAll('.nav-item');
    if (tabName === 'home') navButtons[0].classList.add('active');
    if (tabName === 'songs') navButtons[1].classList.add('active');
    if (tabName === 'vault') navButtons[2].classList.add('active');
    if (tabName === 'profile') navButtons[3].classList.add('active');
}

// 2. Playback Ingest Automation System
function playSong(trackId) {
    const track = dynamicTrackDatabase[trackId];
    if (!track) return;

    activelyPlayingTrackId = trackId;

    const songTitleElement = document.getElementById('song-title');
    const player = document.getElementById('audio-player');
    const source = document.getElementById('audio-source');

    songTitleElement.innerText = track.title;
    source.src = track.audioUrl;
    player.load();
    player.play();

    // Dynamically trigger the active view transformation pipeline layer for manual text layers
    renderLyricsDisplay(trackId);
}

// 3. Media Ingestion Node Engine (Artist Dashboard Preference)
function handleFileUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    const audioUrl = URL.createObjectURL(file);
    const cleanTitle = file.name.replace(/\.[^/.]+$/, "");
    const trackId = "track_" + Date.now();
    
    // Scrape running data cache context fields from manual layout text fields
    const typedLyrics = document.getElementById('manual-lyrics-input').value.trim();

    // Map properties structural dataset mapping configurations directly
    dynamicTrackDatabase[trackId] = {
        id: trackId,
        title: cleanTitle,
        audioUrl: audioUrl,
        lyrics: typedLyrics || ""
    };

    const noSongsMsg = document.getElementById('no-songs-msg');
    if (noSongsMsg) { noSongsMsg.remove(); }

    const songListContainer = document.getElementById('dynamic-song-list');
    const newButton = document.createElement('button');
    newButton.className = 'song-btn';
    newButton.id = `btn_${trackId}`;
    newButton.innerHTML = `🎵 ${cleanTitle}`;
    
    newButton.onclick = function() {
        playSong(trackId);
    };

    songListContainer.appendChild(newButton);
    playSong(trackId);
}
// 4. Custom Manual Lyrics Update Implementation Engine
function saveManualLyrics() {
    const lyricsText = document.getElementById('manual-lyrics-input').value.trim();
    
    if (!activelyPlayingTrackId) {
        alert("Please load or play a track first using Step 1 before assigning manual lyrics to it!");
        return;
    }

    // Write directly into internal variable memory configuration cache layer
    dynamicTrackDatabase[activelyPlayingTrackId].lyrics = lyricsText;
    
    // Command instant refresh layout cycles
    renderLyricsDisplay(activelyPlayingTrackId);
    alert("Lyrics updated successfully for the current track!");
}

// Layout Presentation Transform Engine Layer
function renderLyricsDisplay(trackId) {
    const track = dynamicTrackDatabase[trackId];
    const lyricsBox = document.getElementById('active-lyrics-display');
    const lyricsTextElement = document.getElementById('active-lyrics-text');

    if (track && track.lyrics !== "") {
        lyricsBox.classList.remove('hidden');
        // Translate structural data lines cleanly into native display lines breaking elements
        lyricsTextElement.innerHTML = track.lyrics.replace(/\n/g, '<br>');
        document.getElementById('manual-lyrics-input').value = track.lyrics;
    } else {
        lyricsBox.classList.add('hidden');
        lyricsTextElement.innerHTML = "";
    }
}

// 5. Active Newsletter Ingest Hook
function subscribeFan() {
    const emailInput = document.getElementById('fan-email');
    const emailValue = emailInput.value.trim();

    if (emailValue === "") {
        alert("Please enter a valid email address!");
    } else {
        alert(`Awesome! ${emailValue} has been added to the Inner Circle. Stay tuned for updates!`);
        emailInput.value = ""; 
    }
}

// 6. Interactive Multi-Functional Fan Vault Engine Manager
function triggerVaultAction(type, itemName = '') {
    if (type === 'video') {
        alert("🎬 Loading Behind-the-Scenes Trailer... (Exclusive video feature drops fully in Phase 2!)");
    } else if (type === 'merch') {
        alert(`🛍️ "${itemName}" Pre-order option selected! Merch vault purchase functionality arriving next update.`);
    } else if (type === 'concert') {
        alert("🎫 Scanning tour database... No local shows scheduled yet. You'll get an alert here instantly when tour dates drop!");
    } else if (type === 'release') {
        alert("📅 'No Signal Days' is currently in post-production. The exclusive dynamic countdown timer activates in Phase 2!");
    }
}


// ================= MUSIC SCREEN =================

function openMusicScreen() {
    const screen = document.getElementById("music-screen");

    if (screen) {
        screen.classList.add("active");
        document.body.classList.add("music-open");
    }
}

function closeMusicScreen() {
    const screen = document.getElementById("music-screen");

    if (screen) {
        screen.classList.remove("active");
        document.body.classList.remove("music-open");
    }
}

function searchSongs() {
    const searchInput = document.getElementById("song-search");
    const songs = document.querySelectorAll(".song-row");

    if (!searchInput) return;

    const searchTerm = searchInput.value.toLowerCase().trim();

    let visibleSongs = 0;

    songs.forEach(song => {
        const title = song.dataset.title.toLowerCase();

        if (title.includes(searchTerm)) {
            song.style.display = "flex";
            visibleSongs++;
        } else {
            song.style.display = "none";
        }
    });

    const count = document.getElementById("song-count");

    if (count) {
        count.textContent =
            `${visibleSongs} song${visibleSongs === 1 ? "" : "s"}`;
    }
}

function playSong(songTitle) {
    const player = document.getElementById("song-player");
    const title = document.getElementById("player-title");
    const artist = document.getElementById("player-artist");

    if (player) {
        player.classList.add("active");
    }

    if (title) {
        title.textContent = songTitle;
    }

    if (artist) {
        artist.textContent = "Eden";
    }

    document.body.classList.add("player-open");
}





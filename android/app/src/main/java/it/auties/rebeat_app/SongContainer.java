package it.auties.rebeat_app;

import java.util.List;

class SongContainer {
    private List<Song> songs;
    SongContainer(List<Song> songs){
        this.songs = songs;
    }

    List<Song> getSongs() {
        return songs;
    }
}

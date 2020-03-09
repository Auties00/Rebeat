package it.auties.rebeat_app;

class Song {
    private String id;
    private String title;
    private String artist;
    private String image;
    private String path;
    private String duration;

    Song(String id, String title, String artist, String image, String path, String duration){
        this.id = id;
        this.title = title;
        this.artist = artist;
        this.image = image;
        this.path = path;
        this.duration = duration;
    }
}

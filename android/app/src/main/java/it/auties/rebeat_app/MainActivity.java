package it.auties.rebeat_app;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaMetadataRetriever;
import android.net.Uri;

import android.os.Bundle;
import android.provider.MediaStore;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "it.auties.query/song").setMethodCallHandler((call, result) -> {
                    if (call.method.equals("getSongs")) {
                        SongContainer songs = fetchSongs(getContext());
                        Log.d("[DATA]", songs.toString());

                        if (songs.getSongs() != null) {
                            Gson gson = new Gson();
                            result.success(gson.toJson(songs));
                        } else {
                            result.error("UNAVAILABLE", "Songs not available.", null);
                        }
                    } else {
                        result.notImplemented();
                    }
                }
        );
    }

    private SongContainer fetchSongs(final Context context) {
        List<Song> files = new ArrayList<>();
        Uri uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
        final String[] COLUMNS = {
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.ARTIST_ID,
                MediaStore.Audio.Media.TRACK,
        };

        String selection = MediaStore.Audio.Media.IS_MUSIC + "!= 0";
        String selection1 =  MediaStore.Audio.Media.DURATION + ">= 30000";
        String sortOrder = MediaStore.Audio.Media.TITLE + " ASC";
        Cursor c = context.getContentResolver().query(uri, COLUMNS, selection + " AND " + selection1, null, sortOrder);
        if (c != null) {
            while (c.moveToNext()) {
                File file = new File(c.getString(c.getColumnIndex(MediaStore.Audio.Media.DATA)));
                if(file.exists()){
                    Song song = toSong(file);
                    if(song == null){
                        continue;
                    }

                    files.add(song);
                }
            }

            c.close();
        }

        return new SongContainer(files);
    }

    public Song toSong(File file){
        MediaMetadataRetriever metaRetriever = new MediaMetadataRetriever();
        try {
            metaRetriever.setDataSource(getContext(), Uri.fromFile(file));
        }catch (Exception e){
            e.printStackTrace();
        }

        String title;
        try {
            title = metaRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE);
        }catch (Exception e){
            title = "Song";
        }

        if(title == null){
            return null;
        }

        String artist;
        try {
            artist = metaRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST);
        }catch (Exception e){
            artist = "Rebeat";
        }

        if(artist == null){
            return null;
        }

        String duration;
        try {
            duration = metaRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
        } catch (Exception e) {
            duration = "0";
        }

        if(duration == null){
            duration = "0";
        }

        byte[] coverBytes = metaRetriever.getEmbeddedPicture();
        return new Song(UUID.randomUUID().toString(), title, artist, coverBytes == null ? null : bytesToFile(coverBytes).getPath(), file.getAbsolutePath(), duration);
    }

    private File bytesToFile(byte[] coverBytes){
        Bitmap bitmap = BitmapFactory.decodeByteArray(coverBytes, 0, coverBytes.length);
        File cover = new File(getFilesDir(), UUID.randomUUID().toString() + ".jpg");

        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 60, bytes);

        try{
            cover.createNewFile();
            FileOutputStream fo = new FileOutputStream(cover);
            fo.write(bytes.toByteArray());
            fo.close();
        }catch (Exception e){
            e.printStackTrace();
        }

        return cover;
    }
}

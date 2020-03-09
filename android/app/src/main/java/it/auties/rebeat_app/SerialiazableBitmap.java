package it.auties.rebeat_app;

import android.graphics.Bitmap;

import com.google.gson.annotations.Expose;

public class SerialiazableBitmap {
    @Expose(serialize = false, deserialize = false)
    private Bitmap bitmap;
    @Expose
    private String asString;
    public SerialiazableBitmap(Bitmap bitmap){
        this.bitmap = bitmap;
        this.asString = BitmapUtils.bitmapToString(bitmap);
    }

    public Bitmap getBitmap() {
        if(bitmap == null) {
            this.bitmap = BitmapUtils.stringToBitmap(asString);
        }

        return bitmap;
    }

    public String getAsString() {
        return asString;
    }
}

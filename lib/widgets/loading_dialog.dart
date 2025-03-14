import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // Tidak bisa ditutup dengan tap di luar
    builder: (BuildContext dialogContext) {
      return WillPopScope(
        onWillPop: () async => false, // Mencegah tombol back menutup dialog
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(child: Text(message, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

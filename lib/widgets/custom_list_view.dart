import 'package:flutter/material.dart';
import 'package:flutter_maps/utils/models/PlacesAutoCompleteModel.dart';

class CustomListView extends StatelessWidget {
  const CustomListView({super.key, required this.places});
  final List<Features> places;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            height: 60,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                places[index].properties?.name ?? "Error",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return const SizedBox(
            height: 2,
          );
        },
        itemCount: places.length);
  }
}

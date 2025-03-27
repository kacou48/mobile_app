import 'package:flutter/material.dart';

class HomeSearchBar extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchCleared;
  final VoidCallback onFilterTap;
  final bool isSearching;
  final TextEditingController searchController;

  const HomeSearchBar({
    super.key,
    required this.searchQuery,
    required this.isSearching,
    required this.onFilterTap,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusDirectional.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: TextField(
            controller: searchController,
            style: TextStyle(
              color: Colors.black87,
              fontFamily: "Bold",
            ),
            decoration: InputDecoration(
                hintText: 'Chercher ici...',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                ),
                border: InputBorder.none,
                icon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                ),
                suffixIcon: isSearching
                    ? IconButton(
                        onPressed: onSearchCleared,
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[600],
                        ))
                    : null),
            onChanged: onSearchChanged,
          )),
          if (!isSearching)
            IconButton(
                onPressed: onFilterTap,
                icon: Icon(
                  Icons.refresh, //filter_list,
                  color: Colors.grey[600],
                )),
        ],
      ),
    );
  }
}

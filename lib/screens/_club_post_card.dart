import 'package:flutter/material.dart';

class ClubPostCard extends StatefulWidget {
  final String clubName;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final String? avatarUrl;
  final String? tag;

  const ClubPostCard({
    super.key,
    required this.clubName,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    this.avatarUrl,
    this.tag,
  });

  @override
  State<ClubPostCard> createState() => _ClubPostCardState();
}

class _ClubPostCardState extends State<ClubPostCard> {
  bool isLiked = false;
  int likeCount = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              widget.tag == 'Technology'
                  ? Colors.blue.shade50
                  : widget.tag == 'Events'
                  ? Colors.purple.shade50
                  : widget.tag == 'Campus Life'
                  ? Colors.green.shade50
                  : widget.tag == 'Sports'
                  ? Colors.orange.shade50
                  : widget.tag == 'Career'
                  ? Colors.teal.shade50
                  : widget.tag == 'Academics'
                  ? Colors.indigo.shade50
                  : Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundImage: widget.avatarUrl != null
                    ? AssetImage(widget.avatarUrl!)
                    : null,
                backgroundColor: const Color.fromARGB(255, 201, 170, 170),
                child: widget.avatarUrl == null
                    ? Text(widget.clubName[0])
                    : null,
              ),
              title: Text(
                widget.clubName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(widget.timeAgo),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show options menu
                },
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.content, style: const TextStyle(fontSize: 15)),
            ),

            // Image if any
            if (widget.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Image.asset(
                  widget.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

            // Like and Comment Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Like Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLiked = !isLiked;
                        likeCount += isLiked ? 1 : -1;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('$likeCount'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Comment Button
                  GestureDetector(
                    onTap: () {
                      _showCommentSheet(context);
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.comment_outlined),
                        SizedBox(width: 4),
                        Text('Comment'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Share Button
                  GestureDetector(
                    onTap: () {
                      // Implement share functionality
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.share_outlined),
                        SizedBox(width: 4),
                        Text('Share'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Implement comment posting
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

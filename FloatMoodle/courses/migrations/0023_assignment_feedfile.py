# Generated by Django 3.2.8 on 2021-11-27 21:28

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('courses', '0022_assignment_weightage'),
    ]

    operations = [
        migrations.AddField(
            model_name='assignment',
            name='feedfile',
            field=models.FileField(blank=True, upload_to='feedback'),
        ),
    ]
